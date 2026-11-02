# Prompt: add a custom 404 page to the docs site

Copy everything below into a fresh session. It is a self-contained brief; the
new session has no access to the conversation that produced it.

---

## Task

Add a custom `404.html` to the `zagart/docs` documentation site so that
unmatched URLs return a real 404 instead of silently serving the landing page.

**Repo:** `D:\Repositories\docs` (github.com/zagart/docs)
**Live site:** https://zagart-docs.pages.dev
**Stack:** static HTML — Dokka-generated API docs plus hand-written asset pages —
deployed to Cloudflare Pages.

## Why

The site has no `404.html`. Cloudflare Pages therefore treats the project as a
single-page application and serves `/` for any path that does not match a file
(see "Serving Pages" → "Single-page application (SPA) rendering"). Verified
live:

```
/                             200
/definitely-missing-path-xyz  200   <- should be 404
/a/b/c                        200   <- should be 404
```

Consequences: a mistyped URL returns HTTP 200 with the landing page — confusing
for users and bad for search engines. Removed pages (for example the old
`keystone/` tree) keep appearing to "exist" instead of failing honestly.

Adding a top-level `404.html` opts out of SPA fallback and makes missing paths
return 404.

## Current state (verified)

- Tracked source files live in `docs-site-assets/`:
  - `index.html` — landing page
  - `design/index.html` — design library landing page
  - `integration/*.html` — five per-library setup guides (builder, design,
    navigation, storage, ui)
  - `architecture/*.html` — `core.html`, `assisted.html`
- `site/` is **generated output and gitignored**. Never edit it by hand.
- `_generate.ps1` (repo root) builds `site/` locally.
- `.github/workflows/deploy.yml` builds and deploys on CI.

### The trap: assets are copied by explicit name

Neither the script nor the workflow globs `docs-site-assets/**`. Both enumerate
files and directories individually:

`_generate.ps1` (roughly lines 65-78):

```powershell
Copy-Item -LiteralPath "$Assets/index.html"        -Destination (Join-Path $DocsSite "index.html")        -Force
Copy-Item -LiteralPath "$Assets/design/index.html" -Destination (Join-Path $DocsSite "design/index.html") -Force
foreach ($dir in @("integration", "architecture")) { ... }
```

`deploy.yml` (step "Copy landing pages, guides, and architecture"):

```yaml
cp -r docs-site-assets/index.html site/
cp -r docs-site-assets/design site/
cp -r docs-site-assets/integration site/
cp -r docs-site-assets/architecture site/
```

So **dropping `docs-site-assets/404.html` into place does nothing** unless both
are updated. This is the most likely way to ship a silent no-op. Update both in
the same change.

## Requirements

1. **File:** `docs-site-assets/404.html` — one self-contained page. No external
   CSS, JS, fonts, or CDN links. Inline `<style>`, exactly like the other assets.
2. **Wiring:** add the copy step to `_generate.ps1` and `deploy.yml` so the file
   lands at the **root** of `site/` → `site/404.html`.
3. **Root-absolute links.** The page is served for arbitrary depths
   (`/a/b/c`), so a relative link like `architecture/core.html` would resolve
   against `/a/b/` and break. Use leading-slash URLs:
   - `/`
   - `/architecture/core`
   - `/integration/storage`
4. **Match the existing design.** Do not invent a new look. Reuse the token
   block and typography from `docs-site-assets/index.html`:

   ```css
   :root {
     --bg: #0d1117;
     --card: #161b22;
     --border: #30363d;
     --text: #e6edf3;
     --text-muted: #8b949e;
     --accent: #58a6ff;
     --accent-dim: #1f6feb;
   }
   ```

   - Font stack: `-apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif`
   - Global reset: `* { margin: 0; padding: 0; box-sizing: border-box; }`
   - Body: `background: var(--bg)`, `color: var(--text)`, `padding: 2rem`
   - Column: `.main-content { max-width: 900px; margin: 0 auto; }`
   - Cards: `background: var(--card)`, `border: 1px solid var(--border)`,
     `border-radius: 12px`, `padding: 1.5rem 2rem`
   - Link buttons mirror `.card-links a`: accent text,
     `1px solid var(--accent)`, `border-radius: 6px`,
     `padding: 0.35rem 0.75rem`; hover inverts to
     `background: var(--accent); color: #0d1117;`

5. **Content:**
   - `<title>` in the site's established style. Real examples from existing pages:
     `Libraries — API Documentation`, `Design — API Documentation`,
     `Storage — Setup Guide`, `Architecture — Assisted`. Use an em dash (`—`),
     consistent with them.
   - `<html lang="en">` like the other pages.
   - A clear "page not found" `<h1>` and one short explanatory sentence.
   - A small, useful set of links: home, architecture, and at least one
     integration guide.
   - A muted footer line, consistent with the site.
6. **Keep it honest:** no "redirecting in N seconds", no auto-redirect, no
   tracking, and the core message must render with JavaScript disabled.
7. **Accessibility:** semantic heading structure, link text that describes its
   destination (never "click here"), and contrast preserved via the tokens above.

## Non-goals

- Do not touch Dokka output or the library repos.
- Do not add a nested 404 per section — Cloudflare walks up the directory tree,
  so one top-level `/404.html` covers everything.
- Do not restyle existing pages.
- Do not change the deploy mechanism beyond the single copy line.

## Acceptance criteria

1. `site/404.html` exists after running the generator.
2. A missing path returns **HTTP 404** — verify the status code, not just that
   the page renders.
3. The 404 page's links work when reached from a deep path, thanks to
   root-absolute URLs.
4. Existing pages still return 200.
5. Only `docs-site-assets/404.html`, `_generate.ps1`, and `deploy.yml` change.

## Verification

```powershell
# Local build
.\_generate.ps1
Test-Path .\site\404.html

# After deploy — must be 404
curl.exe -o NUL -s -w "%{http_code}\n" https://zagart-docs.pages.dev/no-such-page

# Existing pages — must still be 200
curl.exe -o NUL -s -w "%{http_code}\n" https://zagart-docs.pages.dev/
curl.exe -o NUL -s -w "%{http_code}\n" https://zagart-docs.pages.dev/architecture/core
```

### Note on `.html` URLs

Pages 308-redirects `/x.html` to `/x` (verified: `/architecture/core.html` →
`/architecture/core`). Both forms resolve. When curling, either use the
extension-less form or pass `-L`, otherwise you will read the 308 rather than
the final status.

Deploy runs through the **Deploy API Docs** workflow
(`.github/workflows/deploy.yml`, `workflow_dispatch`). Secrets
`CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` are already configured and
the workflow is currently green.

## Conventions to follow

- Repo skills live in `.agents/skills/`; read `guide-template` before writing
  the page — it documents the shared HTML/CSS conventions for asset pages.
- Update `README.md` only if the new file changes the documented structure.
- Commit message: Conventional Commits, single line, e.g.
  `feat(docs): add a custom 404 page`.
