# P114｜我們的樹 — Web Version V0.013

MyTreeMyRoot

## V0.013 focus

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

Visible web version: `P114 Web Version V0.013`

Static asset cache busting: `?v=0.013`


## V0.013 — Auth UX fix

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


## V0.013 — Tree Management

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

Starting with V0.013, release ZIP files DO NOT contain `config.js`.
They contain only `config-sample.js`.

Your deployed repository must retain its existing production `config.js`.


## V0.013 — Admin moderation

Implemented:
- Photo Review
- Story Review
- Tree Language Management
- Monthly Coverage

Admin navigation now connects all four pages.
Photo/story actions use existing P114 moderation RPCs.
Monthly Coverage uses `P114_AdminGetMonthlyCoverage`.
No `config.js` changes are made by this deployment.

## V0.013 — Navigation and admin entry

- Main page shows `管理介面` only to logged-in `editor` / `admin` users.
- Admin dashboard provides `回主畫面`.
- Admin dashboard adds quick links to the current management modules.
- Production `config.js` is preserved and untouched.

## V0.013 — Scientific Tree Record

- Added admin Scientific Record / Phenology management.
- Added public tree-profile phenology timeline.
- Corrected Tree Language admin RPC contract to the verified backend signature:
  `p_id, p_public_tree_id, p_label_zh, p_label_en, p_description, p_sort_order, p_active`.
- Added `P114_GetTreePhenology` and `P114_AdminUpsertPhenologyRecord` frontend bindings.
- Existing production `config.js` remains untouched.


## V0.013 — Authorization UX

- Shared Auth login is now explicitly separated from P114 project authorization.
- Tree member-write UI is hidden until an active local role (member/editor/admin) is confirmed.
- Logged-in users without P114 access can continue browsing public tree content but cannot invoke member actions.
- Removed unnecessary frontend calls to P114_EnsureProfile; member RPCs create profiles only after backend role checks.
- Photo upload checks P114 authorization before Storage upload, reducing accidental orphan uploads from unauthorized users.
- My Tree, This Month and Me now handle "authenticated but not authorized" explicitly.
- Observation Point entries can now be reopened for editing, and reference photos can be uploaded directly from Tree Management.
- Production config.js remains untouched.


## V0.013 — Photo upload discoverability

- Added prominent "上傳本月照片" actions on every Tree Profile.
- Member upload form now has a stable #photo-upload anchor and clearer copy that both members and admins may submit community photos there.
- My Tree now links directly to the guardian tree's photo upload section.
- Admin Tree Management now explains the admin photo workflow and renames Tree Media to "管理員照片上傳（Tree Media）".
- Admin dashboard Tree Management card now calls out photo upload.
- Production config.js remains untouched.


## V0.013 — Tree creation feedback

- Tree Management now shows whether Institution / Campus prerequisites are ready.
- Create Tree is disabled until at least one Campus exists.
- Tree form uses explicit validation messages instead of silent browser-native validation.
- Tree create/update shows an in-progress state and admin-facing backend error details when a request fails.
- Existing Trees empty state remains valid only when no tree records exist.
- Production config.js remains untouched.


## V0.013 — Find Tree UX

- Added "帶我去找它" to Tree Profile.
- Current GPS is used only to estimate distance; raw coordinates remain hidden from the public UI.
- Distance states follow the P114 rule: >100m 距離中, 20–100m 接近中, <20m 很接近.
- Under 20m the UI explicitly tells users to switch to landmark/environment/tree-feature confirmation instead of trusting GPS as exact tree identification.
- "我找到它了" now records current latitude/longitude when permission is available, allowing the backend to store distance-to-tree; it falls back to a visit without location if permission is denied.
- Explore / Near Me now labels candidates with the same distance states.
- Production config.js remains untouched.


## V0.013 — Admin data quality

- Institution and Campus records are now listed directly under their forms and can be reopened for editing.
- Duplicate Institution names and duplicate Campus names within the same Institution are blocked in the admin UI.
- Campus can be changed to inactive when it should no longer be used; destructive deletion is intentionally not exposed because referenced Campus / Tree data must remain intact.
- Latitude / Longitude inputs use 6 decimal places and are automatically rounded on blur and before save.
- Required fields now show a red * marker.
- Production config.js remains untouched.
