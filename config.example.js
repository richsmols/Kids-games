// ============================================================
//  FAMILY ARCADE — configuration TEMPLATE
//
//  Do NOT put real values here. This file is committed to the repo.
//
//  • On the LIVE site:  GitHub Actions writes the real config.js at deploy
//    time from your repository secrets (see DEPLOY.md). config.js is gitignored.
//  • For LOCAL testing:  copy this file to config.js and fill it in —
//        cp config.example.js config.js
//    Your local config.js is gitignored, so it won't be committed.
//
//  None of these are the Supabase *secret* key — never put that anywhere
//  in this repo. The publishable key is meant to live in the browser.
// ============================================================
window.ARCADE_CONFIG = {
  SUPABASE_URL: "https://YOUR-PROJECT-ref.supabase.co",
  SUPABASE_KEY: "YOUR-PUBLISHABLE-OR-ANON-KEY",
  EMAIL_DOMAIN: "familyarcade.local",
  INVITE_CODE: "letmein"
};
