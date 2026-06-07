# Zagart Libraries — API Documentation

Documentation site for [zagart](https://github.com/zagart) Kotlin Multiplatform libraries, deployed at [zagart-docs.pages.dev](https://zagart-docs.pages.dev).

## Structure

```
docs/
├── docs-site-assets/        # Source files (landing pages, setup guides) — edit these
│   ├── index.html           # Library cards landing page
│   ├── design/index.html    # Design library landing page
│   └── guides/              # Per-library setup guides
│       ├── design.html
│       ├── keystone.html
│       └── navigation.html
├── site/                    # Generated output (gitignored) — full assembled site
├── _generate.ps1            # Local generation script — runs dokka + assembles site/
└── .github/workflows/deploy.yml  # CI: generates + deploys to Cloudflare Pages
```

## Updating docs

### Setup guides (HTML)

Edit files in `docs-site-assets/guides/`, then regenerate and deploy.

### API docs (Dokka)

API docs are generated from source code in each library repo (`design`, `keystone`, `navigation`). Update doc comments there, then run generation here.

## Local generation

```powershell
# Requires: JDK 21, library repos cloned alongside this one
.\_generate.ps1
```

This runs `dokkaGenerate` for each module and assembles everything into `site/`.

## Deployment

- **CI:** Trigger the **Deploy API Docs** workflow from [GitHub Actions](https://github.com/zagart/docs/actions/workflows/deploy.yml) (or run `workflow_dispatch` manually)
- **Schedule:** Runs weekly (Sunday 06:00 UTC)
- **Service:** Cloudflare Pages — `zagart-docs.pages.dev`

The workflow checks out all 3 library repos, generates dokka, copies landing pages and guides from `docs-site-assets/`, and deploys to Cloudflare Pages.
