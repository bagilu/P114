# P114｜我們的樹 — Web Version V0.001

MyTreeMyRoot

## Current status

This is the first static frontend implementation baseline.

Implemented:
- Shared static layout / responsive design
- Supabase client with `storageKey: P114-auth`
- Home
- Founding Trees
- Search
- Explore / Near Me
- Tree Profile
- Monthly photo grid
- Public Tree Language stats
- Public Stories
- Guardian Tree action
- Visit action
- Login
- Basic Admin Dashboard
- Shared API / Auth / Storage / Error modules

Scaffolded:
- This Month
- My Tree
- Me

## Configuration

Copy values into `config.js`:

```js
window.P114_CONFIG = {
  SUPABASE_URL: "...",
  SUPABASE_ANON_KEY: "...",
  P130_REGISTER_URL: "...",
  P130_FORGOT_PASSWORD_URL: "...",
  P130_ACCOUNT_URL: "..."
};
```

Never put a Supabase service-role key in frontend files.

## Local preview

Because ES modules are used, preview with any simple static HTTP server rather than opening `file://` directly.

Examples:
- VS Code Live Server
- Python `python -m http.server`

## Deployment

The site is designed for GitHub Pages.

## Versioning

Visible version:
`P114 Web Version V0.001`

Static assets use:
`?v=0.001`

Increment both together for every user-visible HTML/CSS/JS release.