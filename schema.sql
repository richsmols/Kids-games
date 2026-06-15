-- ============================================================
--  FAMILY ARCADE — database schema
--  Run this once in Supabase → SQL Editor → New query → Run.
--  It is safe to re-run (objects are dropped/recreated).
-- ============================================================

-- ---------- tables ----------
create table if not exists public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  username     text not null unique,
  display_name text,
  status       text not null default 'pending'
                 check (status in ('pending','approved','rejected')),
  is_admin     boolean not null default false,
  created_at   timestamptz not null default now()
);

create table if not exists public.scores (
  id         bigint generated always as identity primary key,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  game       text not null,
  score      integer not null check (score >= 0 and score <= 100000000),
  created_at timestamptz not null default now()
);
create index if not exists scores_game_score_idx on public.scores (game, score desc);

alter table public.profiles enable row level security;
alter table public.scores   enable row level security;

-- ---------- create a profile automatically on sign-up ----------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, username, display_name, status)
  values (
    new.id,
    lower(coalesce(new.raw_user_meta_data->>'username', split_part(new.email,'@',1))),
    coalesce(new.raw_user_meta_data->>'display_name',
             new.raw_user_meta_data->>'username',
             split_part(new.email,'@',1)),
    'pending'
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------- helper functions (security definer = no RLS recursion) ----------
create or replace function public.is_admin()
returns boolean language sql security definer stable set search_path = public as $$
  select exists (select 1 from public.profiles
                 where id = auth.uid() and is_admin = true);
$$;

create or replace function public.is_approved()
returns boolean language sql security definer stable set search_path = public as $$
  select exists (select 1 from public.profiles
                 where id = auth.uid() and status = 'approved');
$$;

-- ---------- profiles policies ----------
drop policy if exists "read own profile"        on public.profiles;
drop policy if exists "admin reads all"          on public.profiles;
drop policy if exists "approved read approved"   on public.profiles;
drop policy if exists "admin updates profiles"   on public.profiles;

create policy "read own profile" on public.profiles
  for select using (id = auth.uid());

create policy "admin reads all" on public.profiles
  for select using (public.is_admin());

create policy "approved read approved" on public.profiles
  for select using (public.is_approved() and status = 'approved');

create policy "admin updates profiles" on public.profiles
  for update using (public.is_admin()) with check (public.is_admin());
-- (no INSERT policy needed: the trigger above inserts as security definer)

-- ---------- scores policies ----------
drop policy if exists "insert own score"   on public.scores;
drop policy if exists "approved read scores" on public.scores;
drop policy if exists "admin read scores"  on public.scores;

create policy "insert own score" on public.scores
  for insert with check (user_id = auth.uid() and public.is_approved());

create policy "approved read scores" on public.scores
  for select using (public.is_approved());

create policy "admin read scores" on public.scores
  for select using (public.is_admin());

-- ---------- leaderboard view (best score per player per game) ----------
drop view if exists public.leaderboard;
create view public.leaderboard
  with (security_invoker = on) as
  select p.username,
         coalesce(p.display_name, p.username) as display_name,
         s.game,
         max(s.score) as best_score,
         count(*)     as plays,
         max(s.created_at) as last_played
  from public.scores s
  join public.profiles p on p.id = s.user_id
  where p.status = 'approved'
  group by p.username, p.display_name, s.game;

grant select on public.leaderboard to authenticated;

-- ============================================================
--  AFTER you have requested your own account from the app,
--  make yourself the admin by running (replace the username):
--
--    update public.profiles
--    set status = 'approved', is_admin = true
--    where username = 'rich';
-- ============================================================
