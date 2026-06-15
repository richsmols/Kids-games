# Family Arcade

A small website where your kids request an account, you approve it, they log in from
anywhere, pick a game, play, and everyone's best scores show up on a shared league table.

```
family-arcade/
├── index.html      ← the arcade: login / request account / dashboard / leaderboard
├── admin.html      ← your console: approve or reject requests, see players & scores
├── config.example.js ← template; real values come from Actions secrets (or a local copy)
├── schema.sql      ← run once in Supabase to create the database
└── games/
    └── maths-arcade-runner.html
```

The whole thing is static files in the browser plus **Supabase** (a free hosted Postgres
database + login system). You don't run any servers.

---

## How the pieces map to your requirements

| You asked for | How it works |
|---|---|
| 1. User requests an account | "Request account" tab — creates a **pending** account |
| 2. Request goes to an admin page to approve/reject | `admin.html` lists pending requests with Approve / Reject |
| 3. Once approved, user logs in (username + password) | Login tab; nobody gets past the gate until status = approved |
| 4. Dashboard of game tiles | Approved users see a tile per game; pick one to play |
| 5. Play and get a score | The game reports its score back when a run ends |
| 6. Scores shown to all users in a league table | `LEAGUE` page — best score per player per game |

---

## Setup (about 15 minutes, one time)

### 1. Create a Supabase project
1. Go to supabase.com, sign up, create a new project (pick a region near you).
2. Wait for it to finish provisioning.

### 2. Create the database
1. In the project, open **SQL Editor → New query**.
2. Paste the entire contents of `schema.sql` and click **Run**.

### 3. Turn off email confirmation (so kids can use usernames, not email)
- **Authentication → Sign In / Providers → Email**: turn **Confirm email** OFF.
- Leave "Allow new users to sign up" ON (that's how account requests are made).

### 4. Provide your keys
- **Project Settings → API**. Copy:
  - the **Project URL**
  - the **publishable** key (`sb_publishable_…`) or legacy **anon** key
- For the **live site**, put these into GitHub Actions **secrets** (`SUPABASE_URL`,
  `SUPABASE_KEY`, `EMAIL_DOMAIN`, `INVITE_CODE`) — see `DEPLOY.md`. The deploy writes
  `config.js` from them automatically.
- For **local testing**, `cp config.example.js config.js` and fill it in (gitignored).
- **Never** use the `secret` / `service_role` key here. It is not needed.

### 5. Deploy the files
Pick any static host. Easiest:
- **Netlify**: drag the `family-arcade` folder onto app.netlify.com/drop.
- or **Vercel** / **Cloudflare Pages** / **GitHub Pages** — upload the folder.

It must be served over **https** (not opened as a local file).

### 6. Make yourself the admin
1. Open the deployed site, go to **Request account**, and create your own (e.g. `rich`).
2. In Supabase **SQL Editor**, run (use your username):
   ```sql
   update public.profiles
   set status = 'approved', is_admin = true
   where username = 'rich';
   ```
3. Go to `/admin.html`, log in — you'll see the console.

Now when the kids request accounts, they appear in your admin console to approve.

---

## Adding another game later (e.g. Dino Chomp)

1. Drop the game's HTML into `games/` (e.g. `games/dino-chomp.html`).
2. When a run ends, have the game post its score to the page that embeds it:
   ```js
   window.parent.postMessage({ type:'arcade-score', game:'dino-chomp', score: finalScore }, '*');
   ```
   (Maths Arcade Runner already does this — copy the `submitScore()` pattern.)
3. In `index.html`, flip the Dino Chomp entry in the `GAMES` list to `ready:true` and
   point `src` at the file. The dashboard tile and a leaderboard section appear automatically.

---

## Honest limitations (worth knowing)

- **Scores are sent from the browser, so a determined kid could fake one** via dev tools.
  For a family leaderboard that's fine. Real anti-cheat needs the score validated on the
  server (a Supabase Edge Function) — easy to add later if it becomes a problem.
- **Reject = suspend, not delete.** Rejecting flips the account to "rejected" so it can't
  log in. Fully deleting the underlying login needs the Supabase dashboard (Authentication →
  Users) or a server function with the secret key — deliberately kept out of the browser.
- **No email notification when a request arrives.** You check the admin page. If you want a
  ping, Supabase Database Webhooks can email you on a new `profiles` row — a later add-on.

## Keeping kids' data sensible
- Logins are **usernames**, not real names or email — keep it that way.
- Don't share the URL publicly or let it get indexed (it's for your family).
- The data you hold is just: username, a chosen display name, and game scores.
