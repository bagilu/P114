# P114｜我們的樹 — Web Version V0.005

MyTreeMyRoot

## V0.005 focus

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

Visible web version: `P114 Web Version V0.005`

Static asset cache busting: `?v=0.005`


## V0.005 — Auth UX fix

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


## V0.005 — Tree Management

Implemented admin workflow:

`Institution → Campus → Species → Tree → Tree Media → Observation Point`

New page:
- `admin/trees.html`

Capabilities:
- Create Institution
- Create Campus
- Create Species
- Create Tree with permanent `Txxxx` ID
- Edit an existing Tree
- Set Founding Tree
- Change tree status (`active/dead/removed/unknown`)
- Upload and register fixed tree media
- Add/edit observation points
- Browse existing trees

Security:
- The page gates itself through an editor/admin RPC.
- All writes continue through P114 admin RPCs.
- No direct browser INSERT/UPDATE/DELETE is used.

### config.js packaging policy

Starting with V0.005, release ZIP files DO NOT contain `config.js`.
They contain only `config-sample.js`.

Your deployed repository must retain its existing production `config.js`.


## V0.005 — Admin moderation

Implemented:
- Photo Review
- Story Review
- Tree Language Management
- Monthly Coverage

Admin navigation now connects all four pages.
Photo/story actions use existing P114 moderation RPCs.
Monthly Coverage uses `P114_AdminGetMonthlyCoverage`.
No `config.js` changes are made by this deployment.
