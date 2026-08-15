# ui.md — The documentation website: architecture and working guide

A static documentation/learning website for this project: the mathematics
and physics behind the model, a guided tour of the power plant, and a
guided tour of the code. The site lives entirely under `ui/` (45 authored
pages: landing + 14 Basic Knowledge + 17 Power Plant incl. the changelog +
14 Code — the site does not read from `docs/` or `src/` at runtime, with
one sanctioned exception noted below). This file is the guide for working
on it: architecture, how-to, conventions, verification, and gotchas.

## Content policy (repeated from the root README)

Site pages describe the **current model only** — no "previously the model
did X" framing on component pages. All correction history (fixes,
symptoms, root causes, remaining residuals) lives on the dedicated
changelog page, `ui/content/plant/changelog.md`; a new fix gets an entry
there, and the affected pages get their *current* numbers updated.

## Goals and audience

- **Learning first, reference second.** A reader who finishes the site in
  order should be able to open `src/+model/PowerPlant.m` and recognize
  every equation.
- **Assumed background:** advanced algebra, basic differential equations.
  Everything else — thermodynamics, heat transfer, turbomachinery,
  control, numerical integration — is taught in Basic Knowledge at the
  depth the model actually needs.
- **Three sections:** Basic Knowledge (toolkit), Power Plant
  (component-by-component), Code (file-by-file).

## Tech stack

| Piece | Choice | Notes |
|---|---|---|
| Bundler | webpack 5 | multi-page build, dev server with live reload |
| Language | TypeScript (strict) | all components and build helpers |
| CSS/UI | Bootstrap 5 (npm, customized via Sass) | no jQuery |
| Math | KaTeX, rendered at build time | browser ships only `katex.css` |
| Code highlighting | Prism.js (`matlab` + `fortran`) | pre-highlighted in Node |
| Content format | Markdown (`markdown-it`) + front-matter (`gray-matter`) | one `.md` per page |

**Architecture decision — MPA, not SPA.** Each content page compiles to
its own `.html` via `html-webpack-plugin` (one instance per page,
generated from the manifest). Deep-linkable pages, trivial static
hosting, no router; the shared shell (navbar, sidebar, prev/next pager,
TOC) is injected at build time by TypeScript template functions, and a
small runtime bundle handles sidebar collapse, theme and scrollspy.

**How markdown becomes HTML** (all in Node during the build):

1. `webpack.config.ts` (run via ts-node) loads `ui/site.config.ts` and
   creates one `HtmlWebpackPlugin` per manifest page.
2. `renderPage` (`ui/pipeline/render.ts`): `gray-matter` splits the
   front-matter; `markdown-it` renders the body —
   `markdown-it-container` maps `:::` blocks to the renderers in
   `components/blocks.ts`, `katex.renderToString()` turns `$…$`/`$$…$$`
   into static HTML, Prism pre-highlights fenced code; `h2`/`h3` tokens
   feed the in-page TOC.
3. `shell({meta, body, sidebar, toc, pager})` wraps the fragment;
   `html-webpack-plugin` injects hashed `styles`/`runtime` bundles.
4. A companion plugin adds `ui/content/` to `contextDependencies` so
   editing a `.md` triggers a dev rebuild. `renderPage` resolves
   cross-page links through the manifest and **throws on unknown ids —
   broken links fail the build.**

## Repository layout

```
/                      repo root (npm files at root, per convention)
├─ webpack.config.ts
├─ ui/                 EVERYTHING site-related, isolated
│  ├─ site.config.ts        section/page manifest (nav order, titles)
│  ├─ components/           shell, navbar, sidebar, pager, toc, blocks
│  ├─ runtime/              browser TS entry (Bootstrap JS, scrollspy…)
│  ├─ styles/               Sass: Bootstrap import + site theme
│  ├─ content/              ALL page sources: index.md, basics/, plant/, code/
│  ├─ assets/               img/, diagrams/
│  └─ pipeline/             build-time helper SOURCE (renderer, manifest
│                           loader, KaTeX macros, abbreviations, identifiers)
└─ dist/                    compiled site (gitignored, the ONLY generated dir)
```

## How-to

- **Build:** `npm run build` (production, to `dist/`). Dev server:
  `npm start`. Also `npm run typecheck`, `npm run lint`.
- **Add a page:** add `{ id: 'section/name', title: '…' }` to
  `ui/site.config.ts` (order = sidebar/pager order), create
  `ui/content/section/name.md` with a `description:` front-matter line,
  build. A manifest entry without a file (or a broken `@id` link) fails
  the build — that's the safety net.
- **Watch-mode scope:** `ui/content/`, `ui/runtime/`, `ui/styles/`
  reload live. `ui/pipeline/`, `ui/components/` and `ui/site.config.ts`
  are loaded once by ts-node at config evaluation — **edits there (or
  new manifest pages) need a dev-server restart.** Never leave a
  background dev server running when done.

## Authoring conventions

- **Page recipe (plant pages):** why it exists → how it works → key
  metrics (100% design values) → governing equations → dynamics (which
  of the 47 states live here) → which thesis test stresses it. Code
  pages: what the file does → the methods with excerpts → a `code-map`.
- **Containers** (`components/blocks.ts`): `equation` (numbered, caption,
  thesis page ref), `definition`, `metrics` (100%-load key figures),
  `why`, `code-map` (symbol → identifier → file; the cross-linking
  workhorse), `caution` (honesty notes), variable tables, `figure`,
  FORTRAN-vs-MATLAB `compare`.
- **Cross-links:** `[text](@section/page)` — resolved and checked
  against the manifest at build time.
- **Math:** KaTeX `$…$` / `$$…$$`; shared macros in
  `ui/pipeline/macros.ts` (`\dot m` ↔ `w`, `\rho` ↔ `r`, `g_c`…).
  English engineering units everywhere, matching the model.
- **Abbreviations (site-wide rule):** first use in a page spelled out
  with the abbreviation in parentheses ("forced-draft (FD) fan"); every
  occurrence auto-wrapped in `<abbr title>` from the central glossary
  `ui/pipeline/abbreviations.ts` (skips code and math). A build lint
  flags any all-caps prose token missing from the glossary. Thesis
  FORTRAN subroutine names (CRSTAT, HXFER, ARFLOW, …) are glossaried.
- **Identifiers:** thesis variable names in *inline code spans* and
  fenced blocks (`kjtre`, `whp`, `cfld`, …) get tooltips from
  `ui/pipeline/identifiers.ts` (case-insensitive; ~100 entries).
  Deliberately not applied to prose — `card`/`delta` collide with
  English. When you introduce a new identifier on a page, add it there.
- **Code excerpts must match `src/+model`.** Verify identifiers and
  signatures against the source before citing (past catch:
  `superheatedSteam` vs `superheaterSteam`; excerpts of `step` and
  `derivative` went stale when their signatures changed). Pages with
  `sourceFile:` front-matter (a path or YAML list → tabbed modal) get a
  **view-source modal** read from `src/` at build time — the one
  sanctioned exception to the isolation rule, so listings can never go
  stale and a renamed model file fails the build.

## Verification checklist (run after any content change)

1. `npm run build` — must compile with **no output** from the abbr lint
   (silence = pass) and no broken-link errors.
2. **Raw-math sweep:** grep `dist/` HTML for unrendered `$` sequences
   (hard-wrapped `$…$` spans once broke silently; the math plugin now
   tolerates soft line breaks, but keep the sweep).
3. Spot-check the rendered `dist/` page — beware that grep for a phrase
   like "603 MW" can miss because `<abbr>` markup splits it.
4. **If `ui/pipeline/` or `ui/components/` changed for the book's sake**
   (see "The book build"): the site must be unaffected — byte-identical,
   not just "looks fine". Verify by building, hashing, and comparing
   against a build with the change reverted:
   `find dist -name '*.html' | sort | xargs md5sum | md5sum`.
   The book may only extend `renderBody` with *optional* hooks whose
   defaults reproduce site behavior exactly (`renderPage` passes none).

## Gotchas (learned the hard way)

- `markdown-it-container`'s types clash with markdown-it v14 — cast the
  plugin via `Parameters<MarkdownIt['use']>[0]`.
- Inline SVG in markdown works as an `html_block` — but **no blank lines
  inside the SVG**, or the parser splits it. The abbr plugin skips
  `html_block`, so SVG text is safe from wrapping.
- The identifier-tooltip pass on fenced blocks runs over Prism's *text
  nodes* only (`wrapIdentifiersInHtml` splits on tags) — keep it that
  way or tooltips corrupt the markup.
- KaTeX `$…$` spans survive soft line breaks (hard-wrapped prose); the
  raw-math sweep exists because this once failed silently.
- The pager is intra-section: the last page of a section gets no "next"
  link — hand off to the next section in prose (see
  `plant/changelog.md`'s closing line).
- Fact-check catch to remember: `kc2fn = 0` in the deck — the
  furnace-pressure air feedforward is zero-gained; don't describe it as
  active.

## The book build (book/)

The site's content also compiles into an A5 print book:
`npm run book` → `dist-book/usoro-plant-book.pdf` (`book:html` stops at
the HTML). Everything book-specific lives in `book/` — assembly
(`build-book.ts`: cover, preface, contents, three parts from the
manifest, appendix listings from `sourceFile:` front-matter, glossary +
identifier tables from the pipeline's own data), the paged-media
stylesheet (`book.css`), and a build-time hard-wrapper for long code
lines (`wrap-code.ts`, 70-column measure, `↪` continuations). The
renderer is shared, not forked: `renderPage` (site) and the book both
call `renderBody` (`ui/pipeline/render.ts`), whose optional hooks
(cross-link resolution, heading-id prefix, modal/equation toggles) are
what the book overrides. Content edits therefore flow into both outputs;
keep wording medium-neutral where possible. Rendering is Paged.js via
`pagedjs-cli` (headless Chromium); key gotchas learned (never
`text-align: justify` under Paged.js; `string-set` needs in-flow
carriers; prism.css re-blocks `pre-wrap` on inner `<code>`) are recorded
as comments in `book.css`.

## Not built (deliberate)

Client-side search (revisit with lunr.js if wanted); in-browser
simulation (a TS/WASM port is a separate project); per-component SVG
diagrams (pages are prose-first; the clickable plant schematic on
`plant/overview` is the only diagram); print styles and favicon. Mobile
navigation is handled: below `lg` the navbar collapse carries the
current section's full page map plus other-section jump links (the
sidebar is `d-none` there), capped at 75vh with its own scrollbar.
Deployment: `dist/` works from any static file server; hosting choice
deferred.
