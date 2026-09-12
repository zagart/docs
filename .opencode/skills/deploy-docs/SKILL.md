---
name: deploy-docs
description: Use when deploying the docs site (e.g. "commit & push & deploy", "deploy docs", "publish site"). Builds with _generate.ps1 and deploys to Cloudflare Pages.
---

# Deploy Docs Site

## Prerequisites

- All sibling repos (`../design`, `../storage`, `../navigation`) must be present with their latest code.
- Wrangler must be authenticated: `npx wrangler whoami`

## Deploy steps

1. **Build the site** — Run `_generate.ps1` from the repo root:
   ```
   pwsh ./_generate.ps1
   ```
   This generates Dokka docs from sibling repos and copies static assets into `site/`.

2. **Deploy to Cloudflare Pages** — Use wrangler to deploy the `site/` directory:
   ```
   npx wrangler pages deploy site --project-name zagart-docs --branch main
   ```

3. **Verify** — Check the deployment URL printed by wrangler (e.g. `https://<hash>.zagart-docs.pages.dev`). The production domain is `zagart-docs.pages.dev`.

## When to skip the build

If only `docs-site-assets/` files were changed (HTML, CSS, etc.), the build step can be skipped — just deploy the existing `site/` directly.

## CI fallback

If wrangler is not available locally, push to `main` and trigger the deploy workflow manually at:
https://github.com/zagart/docs/actions/workflows/deploy.yml
