# P114｜我們的樹 — Web Version V0.002

MyTreeMyRoot

## V0.002 focus

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

Visible web version: `P114 Web Version V0.002`

Static asset cache busting: `?v=0.002`
