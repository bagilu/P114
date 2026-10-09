# P114｜我們的樹 — Web Version V0.003

MyTreeMyRoot

## V0.003 focus

This release completes the first member journey:

`Explore → Tree Profile → Guardian / Tree Language / Story / Photo → My Tree / Me`

Implemented:
- Home / Founding Trees
- Search
- Explore / Near Me
- Tree Profile
- Monthly representative photo grid
- Community photo upload + pending moderation workflow
- Tree Language submission/edit
- Story submission
- Guardian Tree + visit actions
- This Month
- My Tree
- Me / logout / P130 account link
- Login
- Basic Admin Dashboard

## Important deployment note

**Do not overwrite your working production `config.js` with the blank file in this package.**
Keep the existing deployed `config.js`, or copy the real values into the new file before publishing.

Required keys:

```js
window.P114_CONFIG = {
  SUPABASE_URL: "...",
  SUPABASE_ANON_KEY: "...",
  P130_REGISTER_URL: "...",
  P130_FORGOT_PASSWORD_URL: "...",
  P130_ACCOUNT_URL: "..."
};
```

Never place a Supabase service-role key in frontend files.

## Version

Visible web version: `P114 Web Version V0.003`

Static asset cache busting: `?v=0.003`


## V0.003 — Auth UX fix

Changes:
- Every main topbar now reflects the actual P114 Supabase session.
- Logged-out state: `登入`.
- Logged-in state: `已登入 · <account>` plus `登出`.
- Login page explicitly shows success/failure.
- Existing P114 session is visible when returning to login page.
- Password has a show/hide control.
- P130 registration and forgot-password buttons are prominent.
- Missing P130 URLs now produce an explicit configuration message instead of silently linking to `#`.

### Important: Shared account ≠ shared browser session

P130 and P114 use the same Supabase `auth.users` account identity, but P114 deliberately uses
`storageKey: P114-auth`. A login performed on P130 does not automatically make the P114 browser
session logged in. Users can use the same email/password on P114.

If true cross-site SSO is desired later, it needs an explicit P130→P114 session handoff/SSO design;
do not emulate it by sharing passwords or service-role keys.

### Production config

When deploying this ZIP, keep your existing real Supabase values in `config.js`, and add real P130 URLs:

```js
P130_REGISTER_URL: "https://...",
P130_FORGOT_PASSWORD_URL: "https://...",
P130_ACCOUNT_URL: "https://..."
```
