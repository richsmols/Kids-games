# Deploying to GitHub Pages + reggieandrobin.uk

This repo deploys itself to GitHub Pages on every push to `main`, via
`.github/workflows/deploy.yml`. The site is served at **https://reggieandrobin.uk**.

## One-time push (from the folder you downloaded)

```bash
# 1. Clone your repo
git clone https://github.com/richsmols/Kids-games.git
cd Kids-games

# 2. Copy ALL files from the downloaded family-arcade folder into here,
#    including the hidden ones: .github/, .gitignore, .nojekyll, CNAME,
#    and config.example.js. (Do NOT create a real config.js — the deploy
#    builds it from your secrets. config.js is gitignored on purpose.)
#    (on macOS Finder, press Cmd+Shift+. to see hidden files)

# 3. Commit and push
git add .
git commit -m "Family Arcade site + GitHub Pages deployment"
git push origin main      # if your default branch is 'master', use that, or rename to main
```

If the repo is brand new and empty, after copying files in:
```bash
git add .
git commit -m "Family Arcade site + GitHub Pages deployment"
git branch -M main
git push -u origin main
```

Prefer the browser? GitHub repo → **Add file → Upload files** → drag everything in →
Commit. (Upload `.github/workflows/deploy.yml` by typing that path in **Add file →
Create new file**, since the uploader hides dotfolders.)

## GitHub settings (once)

1. Repo → **Settings → Secrets and variables → Actions → New repository secret**.
   Add these four (the deploy writes them into `config.js` at build time):

   | Secret name     | Value |
   |-----------------|-------|
   | `SUPABASE_URL`  | your Project URL, e.g. `https://abc123.supabase.co` |
   | `SUPABASE_KEY`  | your **publishable** key (`sb_publishable_…`) or legacy **anon** key |
   | `EMAIL_DOMAIN`  | any domain text, e.g. `reggieandrobin.uk` (never receives mail) |
   | `INVITE_CODE`   | the word kids type to request an account |

   Do **not** add the Supabase *secret* / service_role key. It is never needed here.

2. Repo → **Settings → Pages → Build and deployment → Source** = **GitHub Actions**.
3. Push. The **Actions** tab shows the deploy running; it goes green in ~1 min.
   (If a secret is missing the build fails with a clear message telling you which one.)
4. Back in **Settings → Pages → Custom domain**, type `reggieandrobin.uk`, Save.
5. When the DNS check passes, tick **Enforce HTTPS** (cert can take a few minutes).

## DNS (at whoever you bought reggieandrobin.uk from)

Apex domain `reggieandrobin.uk` — four **A** records (all with host `@` or blank):

```
185.199.108.153
185.199.109.153
185.199.110.153
185.199.111.153
```

Optional IPv6 — four **AAAA** records (same host `@`):

```
2606:50c0:8000::153
2606:50c0:8001::153
2606:50c0:8002::153
2606:50c0:8003::153
```

`www` subdomain — one **CNAME** record: host `www` → value `richsmols.github.io`

DNS can take up to 24 hours to propagate (often minutes). HTTPS is issued by GitHub
automatically once the domain resolves.

## Adding a new game later (the whole point)

1. Drop the game's HTML into `games/` (e.g. `games/dino-chomp.html`).
2. Make it report its score when a run ends:
   `window.parent.postMessage({ type:'arcade-score', game:'dino-chomp', score: finalScore }, '*');`
3. In `index.html`, set that game's `ready:true` and point `src` at the file.
4. `git add . && git commit -m "Add Dino Chomp" && git push` — live in ~1 minute.

## Local testing (optional)

The repo has no `config.js` — it's generated at deploy. To run the site on your own
machine, copy the template and fill it in (your copy stays gitignored):

```bash
cp config.example.js config.js   # then edit config.js with your values
python3 -m http.server 8000       # open http://localhost:8000
```

## Notes / honest caveats

- **The four values are now out of the repo and git history** — they live in GitHub
  Actions secrets and are written into `config.js` only during the deploy. Rotate them
  any time in Settings → Secrets, no code change needed.
- **They are still visible in the *deployed* site.** A client-side app has to ship the
  publishable key and the invite code to the browser, so anyone who views source on
  reggieandrobin.uk can read them. That's expected and safe for the publishable key
  (it's designed to be public; Row Level Security protects your data). It does mean the
  invite code remains only a soft gate — **admin approval is the real security boundary.**
  Truly hiding the invite code would need server-side checking (a Supabase Edge Function),
  which is a larger change.
- **Never** add the Supabase *secret* / service_role key anywhere in this repo.
- If you already committed a real `config.js` in an earlier push, untrack it:
  `git rm --cached config.js && git commit -m "stop tracking config.js" && git push`.
- `schema.sql` and the docs get published too (e.g. reggieandrobin.uk/schema.sql).
  Harmless, but you can delete `schema.sql` from the repo after running it if you'd rather.
