---
name: guide-template
description: Use when creating or editing library setup guides in docs-site-assets/guides/. Provides the exact HTML structure, CSS token classes, and section order every guide must follow.
---

# Guide Page Template

Each library setup guide is a standalone HTML file in `docs-site-assets/integration/`. They all follow the same structure:

## Sections (in order)

1. **Title + subtitle** — `<h1>` with library name, `<p class="subtitle">` with Maven coordinate(s) and module list
2. **Module table** — `<h2>Module(s)</h2>`, table with columns: `Module`, `Artifact`, `Targets`
3. **Installation** — `<h2>Installation</h2>`, Gradle `commonMain.dependencies { ... }` snippet in a `<pre><code>`
4. **Basic Usage** — `<h2>Basic Usage</h2>`, a compilable Kotlin snippet with `token-*` CSS span classes for syntax highlighting
5. **Features** — `<h2>Features</h2>`, table with columns: `Feature`/`Module`, `Details`
6. **Versioning & Releases** — `<h2>Versioning & Releases</h2>`, ordered list of release steps
7. **Back link** — `<div class="back"><a href="../">&larr; Back</a></div>`

## Styling

All pages share an identical `<style>` block (dark theme, GitHub-like). Token classes used in code snippets:

| Class            | Applies to                         |
|------------------|------------------------------------|
| `token-keyword`  | `val`, `var`, `override`, `->`     |
| `token-string`   | String literals                    |
| `token-comment`  | `//` comments                      |
| `token-func`     | Function/method calls              |

## Keeping versions current

Each guide hardcodes the library version in two places: the Installation snippet and the Versioning tag step. Before deploying, grep the actual version from the library's `build.gradle.kts` (`version = "..."`) and update both spots. Versions drift independently per library.

## Adding a new guide

1. Copy `storage.html` (the simplest — single module)
2. Update `<title>`, `<h1>`, subtitle, module table rows, artifact coordinates, usage snippet, feature table, and versioning steps
3. Add a card link in `index.html`
4. Regenerate and deploy via `_generate.ps1`
