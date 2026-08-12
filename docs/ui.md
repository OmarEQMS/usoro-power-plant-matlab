# ui.md — Documentation & learning site plan

A static documentation/learning website for this project: the mathematics
and physics behind the model, a guided tour of the power plant, and a
guided tour of the code. This file is the build plan; the site itself
lives entirely under `ui/` (all site content included — the site does not
read from `docs/` or `src/` at runtime).

## Goals and audience

- **Learning first, reference second.** A reader who finishes the site in
  order should be able to open `src/+model/PowerPlant.m` and recognize
  every equation.
- **Assumed background:** advanced algebra, basic differential equations
  (what an ODE and an initial-value problem are). Everything else —
  thermodynamics, heat transfer, turbomachinery, control theory, numerical
  integration — is taught in the Basic Knowledge section at the depth the
  model actually needs, no more.
- **Three sections** (top-level navigation):
  1. **Basic Knowledge** — the math/physics toolkit.
  2. **Power Plant** — component-by-component walkthrough: what it is,
     why it exists, its design metrics, its governing equations.
  3. **Code** — file-by-file walkthrough: what each class does, what each
     variable tracks, and how the plant equations become MATLAB.

## Tech stack

| Piece | Choice | Notes |
|---|---|---|
| Bundler | webpack 5 | multi-page build, dev server with live reload |
| Language | TypeScript (strict) | all components and build helpers |
| CSS/UI | Bootstrap 5 (npm, customized via Sass) | navbar, sidebar, cards, tables; no jQuery |
| Math | KaTeX (build-time render preferred) | every equation page is LaTeX-heavy |
| Code highlighting | Prism.js with `matlab` + `fortran` grammars | MATLAB sources, thesis FORTRAN excerpts |
| Content format | Markdown (`markdown-it`) with front-matter (`gray-matter`) | one `.md` per page, compiled at build time |
| Diagrams | static SVG files authored in `ui/assets/diagrams/` | plant schematics, loop block diagrams |

**Architecture decision — MPA, not SPA.** Each content page compiles to
its own `.html` via `html-webpack-plugin` (one instance per page,
generated from the content manifest). Rationale: deep-linkable pages,
trivial static hosting, no router code; the shared shell (navbar, sidebar,
prev/next) is injected at build time by TypeScript "HTML components"
(template functions), and a small runtime bundle handles the interactive
bits (sidebar collapse, theme, scrollspy TOC).

**How markdown becomes HTML.** All rendering happens in Node while
webpack builds — no markdown, KaTeX or Prism JS ships to the browser:

1. `webpack.config.ts` (run via ts-node so it can import the TS
   components) loads `ui/site.config.ts` and creates one
   `HtmlWebpackPlugin({ filename: page.out, templateContent:
   () => renderPage(page), chunks: ['runtime', 'styles'] })` per page.
2. `renderPage` (`ui/pipeline/render.ts`): `gray-matter` splits the
   front-matter; `markdown-it` renders the body —
   `markdown-it-container` maps the `:::` blocks to the renderers in
   `components/blocks.ts`, `katex.renderToString()` turns `$…$`/`$$…$$`
   into static HTML at build time (browser loads only `katex.css`), and
   Prism's Node API pre-highlights fenced code; `h2`/`h3` tokens are
   collected for the in-page TOC along the way.
3. The fragment is wrapped by `shell({meta, body, sidebar, toc, pager})`
   into a full document; `html-webpack-plugin` injects the hashed
   `<link>`/`<script>` tags for the shared `styles`/`runtime` bundles and
   emits the file.
4. A small companion plugin adds `ui/content/` to the compilation's
   `contextDependencies` so editing a `.md` triggers a dev-server
   rebuild (webpack doesn't otherwise know the markdown is an input).
   `renderPage` resolves cross-page links through the manifest and
   throws on unknown page ids — broken links fail the build there.

Both `npm start` and `npm run build` run this same pipeline; serve just
keeps re-running it. Watch-mode scope: `ui/content/`, `ui/runtime/` and
`ui/styles/` reload live; `ui/pipeline/`, `ui/components/` and
`ui/site.config.ts` are loaded once by ts-node at config evaluation and
cached in the Node process, so edits there (or new manifest pages)
require restarting the dev server.

## Repository layout

```
/                      repo root
├─ package.json        npm files live at root (per project convention)
├─ tsconfig.json
├─ webpack.config.ts
├─ ui/                 EVERYTHING site-related, isolated
│  ├─ site.config.ts        section/page manifest (nav order, titles)
│  ├─ components/           TS template functions ("HTML components")
│  │  ├─ shell.ts           page skeleton: <head>, navbar, sidebar, footer
│  │  ├─ navbar.ts          three-section top nav + brand
│  │  ├─ sidebar.ts         per-section page tree with active state
│  │  ├─ pager.ts           prev/next footer links from manifest order
│  │  ├─ toc.ts             in-page heading TOC (right rail, scrollspy)
│  │  └─ blocks.ts          content building blocks (see below)
│  ├─ runtime/              browser TS entry (Bootstrap JS, scrollspy…)
│  ├─ styles/               Sass: Bootstrap import + site theme
│  ├─ content/              ALL page sources (markdown + front-matter)
│  │  ├─ index.md           landing page
│  │  ├─ basics/            section 1 pages
│  │  ├─ plant/             section 2 pages
│  │  └─ code/              section 3 pages
│  ├─ assets/
│  │  ├─ img/               figures (copied from docs/img where useful)
│  │  └─ diagrams/          SVG schematics
│  └─ pipeline/             build-time helper SOURCE (md renderer, manifest
│                           loader, KaTeX macros, abbreviation glossary) —
│                           runs in Node during the build, emits nothing here
└─ dist/                    compiled site output (gitignored) — the ONLY
                            generated folder; all HTML/CSS/JS lands here
```

npm scripts: `npm start` (dev server), `npm run build` (production to
`dist/`), `npm run typecheck`, `npm run lint`.

## Content building blocks (`components/blocks.ts`)

Rendered from markdown via small custom containers
(`markdown-it-container`), all Bootstrap-styled:

- **`::: equation`** — numbered display equation with a caption and an
  optional thesis page reference.
- **`::: definition`** — term/symbol callout (name, symbol, unit,
  one-line meaning). Used heavily in Basic Knowledge.
- **`::: metrics`** — key-figures card grid for a component (e.g. drum:
  2778 psia, 1958.7 ft³, …) with the 100%-load design values.
- **`::: why`** — motivation callout ("why does this component exist").
- **`::: code-map`** — table mapping symbols → code identifiers → file,
  linking into the Code section. The workhorse of cross-linking.
- **`::: caution`** — honesty notes (model limitations, known offsets).
- Variable tables, figure-with-caption, FORTRAN-vs-MATLAB side-by-side
  compare block.

**Cross-linking model:** every plant component page links (a) back to the
Basic Knowledge pages it relies on and (b) forward to the code page that
implements it; every code page links back to the plant component(s) it
models. The manifest holds these relations so links are checked at build
time (broken link = build failure).

**Math conventions:** shared KaTeX macro file (`ui/pipeline/macros.ts`) for
recurring symbols — mass flow `\dot m` ↔ `w`, enthalpy `h`, density
`\rho` ↔ `r`, the 1–5 V control scale, `g_c = 32.174`. Every page states
units in English engineering units, matching the model.

**Abbreviation policy (site-wide rule):** every abbreviation carries its
long name — on first use in a page it is spelled out with the
abbreviation in parentheses ("forced-draft (FD) fan"), and *every*
occurrence is wrapped in `<abbr title="long name">` so hovering shows a
tooltip (Bootstrap styles `abbr[title]` with a dotted underline and help
cursor out of the box). Mechanism: a single central glossary
(`ui/pipeline/abbreviations.ts` — e.g. FD/ID = forced/induced draft,
HP/IP/LP = high/intermediate/low pressure, PI = proportional–integral,
ODE = ordinary differential equation, RK4 = 4th-order Runge–Kutta,
LDC = load demand computer, IC = initial condition, TOC = table of
contents), applied automatically by a markdown-it pass that wraps known
abbreviations in prose while skipping code spans/blocks and math. A build
lint flags any all-caps token in prose that is missing from the glossary,
so new abbreviations cannot slip in undocumented.

The same treatment extends to **model identifiers**: thesis variable
names appearing in *inline code spans* (`kjtre`, `whp`, `cfld`, …) get
tooltips from a second dictionary, `ui/pipeline/identifiers.ts`, matched
case-insensitively (`KJTRE` and `kjtre` both resolve) and decoded per the
thesis naming scheme (k·J·TRE = constant, inertia J, TuRbine-gEnerator).
Identifiers are deliberately NOT wrapped in prose text — names like
`card` and `delta` collide with English words, so code context is the
signal that a token is an identifier. Fenced blocks get the same
treatment: after Prism highlights, the wrapper runs over the *text
nodes* of the output (never inside tags), so variables in code listings
are hoverable too.

## Section 1 — Basic Knowledge (`ui/content/basics/`)

Ordered so each page uses only earlier pages. Target: someone who can
manipulate equations but has never seen thermodynamics.

| # | Page | Scope (what the model actually needs) |
|---|---|---|
| 1 | `units.md` | English engineering units; lbm vs lbf and `g_c`; psia; °F vs °R; Btu; why `WR²/g_c` matters (the kjtre story foreshadowed) |
| 2 | `state-variables.md` | systems, states, inputs; ODEs as `ẋ = f(t, x)`; equilibrium/steady state; what "47th order" means |
| 3 | `mass-energy-balances.md` | control volumes; conservation of mass and energy; accumulation = in − out; where every `xdot` in the model comes from |
| 4 | `thermo-properties.md` | pressure/temperature/density/enthalpy/entropy; ideal vs real; the water phase diagram; saturation, quality, superheat |
| 5 | `steam-tables.md` | what steam tables are; why the model uses polynomial fits; reading a fit like `hi = -1211.8 + 683.58·r + 1384.39·s`; fit validity ranges |
| 6 | `fluid-flow.md` | pressure-driven flow; orifice/friction laws `w = √(Δp·ρ/k_f)`; flow networks; solving series/parallel branches (quadratics) |
| 7 | `pumps-fans.md` | pump/fan curves (head vs flow, quadratic in speed); operating point = curve ∩ system resistance; affinity with speed |
| 8 | `turbines.md` | expansion work; isentropic enthalpy drop and isentropic efficiency `h_o = h_1 − η(h_1 − h_i)`; extraction; stage pressure ∝ flow |
| 9 | `heat-transfer.md` | conduction/convection/radiation at model depth; `q = UA·ΔT` effectiveness forms; radiant `q ∝ T⁴`; metal thermal mass |
| 10 | `rotating-machinery.md` | Newton for rotors `J·ω̇ = ΣT`; torque vs power; inertia constants; induction motors and slip; the WR²/g_c pitfall in full |
| 11 | `generator-grid.md` | synchronous machine as a spring: power angle δ, `P = P_max·sin δ`, infinite bus, the undamped swing equation |
| 12 | `control-basics.md` | feedback; error, P and PI control; integrators and why they zero steady-state error; actuator lags (first-order) |
| 13 | `control-practices.md` | signal normalization (the 1–5 V scale, transducers); set-point scheduling; cross-limiting (air/fuel); deadbands; saturation and windup |
| 14 | `numerical-integration.md` | explicit Euler and its instability on oscillators; RK4; stability regions; fixed step Ts = 0.1 s; why integrator choice is a correctness issue here |

## Section 2 — Power Plant (`ui/content/plant/`)

Follows the water/steam path, then air/gas, then electricity, then the
control room. Every page: **Why it exists → How it works → Key metrics
(100% design values) → Governing equations → Dynamics (which of the 47
states live here) → Where it can break (which thesis test stresses it)**.

| # | Page | Component(s) |
|---|---|---|
| 1 | `overview.md` | the 600 MW unit; reheat Rankine cycle diagram; boiler-following operation; the seven emergency tests as a tour guide |
| 2 | `furnace.md` | furnace & burners: combustion, fuel heat `w_fl·k_hfl`, burner tilt, gun count, radiant transfer to waterwalls (T⁴ balance) |
| 3 | `waterwalls-drum.md` | waterwalls, drum, downcomers, recirculation pumps: circulation loop, saturated equilibrium, drum level dynamics, blowdown |
| 4 | `superheaters.md` | primary/secondary superheater + desuperheater spray: convective absorption, steam temperature control, main steam conditions (2415 psia / 1000 °F) |
| 5 | `reheater.md` | reheater + reheat spray: why reheat exists (moisture/efficiency), tilt-based temperature control, gas recirculation support |
| 6 | `economizer-airheater.md` | economizer and air heater: feedwater preheat, stack-loss recovery, fixed-temperature air heater treatment |
| 7 | `air-gas-path.md` | FD/ID fans, furnace draft, gas recirculation: the air/gas flow network, fan curves, furnace pressure, the recirc path |
| 8 | `turbine-train.md` | HP → reheat → IP → cross-over → LP: expansion line, extractions, governing stage, first-stage pressure as a flow meter |
| 9 | `condenser.md` | condenser and hotwell: heat rejection, vacuum, quality at exhaust |
| 10 | `feedwater-train.md` | condensate pumps, LP heaters, deaerator (why deaeration; level dynamics), booster + main feed pump, FP turbine, HP heaters |
| 11 | `generator.md` | generator & grid: swing dynamics, power angle, what 60 Hz means to every motor in the plant |
| 12 | `control-room.md` | the control system as a whole: boiler-following philosophy; map of the 11 loops; the 1–5 V signal world |
| 13 | `loops-combustion.md` | boiler master, air, fuel, furnace pressure, gas recirc loops in detail (block diagrams, cross-limits, scheduling) |
| 14 | `loops-steam.md` | feedwater 3-element, deaerator level, FP turbine, superheat spray, reheat tilt loops in detail |
| 15 | `loops-turbine.md` | load reference, governor, droop; grid-following behavior |
| 16 | `emergency-tests.md` | the seven thesis tests: what each stresses, expected traces, capability limits (honest notes on the known fuel/air offset) |

Metrics sources: thesis Tables V.1–V.3 and the model's 100% initial
conditions; where the model deviates from the thesis (documented offsets),
the page says so in a `::: caution` block.

## Section 3 — Code (`ui/content/code/`)

The bridge: "you saw the equation on the plant page — here is the line of
MATLAB." One page per source file plus conventions and worked examples.

| # | Page | Covers |
|---|---|---|
| 1 | `tour.md` | repo layout; `src/+model` package; how a simulation runs end-to-end (one derivative evaluation, annotated) |
| 2 | `conventions.md` | thesis symbol naming (`w`=flow, `h`=enthalpy, `r`=density, `k*`=constants, `c*`=control signals); units; the `sig` signal bus idea |
| 3 | `parameters.md` | `Parameters.m`: generated constants, name families (`kc*`, `ktc*`, `kj*`, `ku*`…), the kjtre correction |
| 4 | `state-vector.md` | `StateVector.m` + the full 47-state table: index, name, unit, plant page link |
| 5 | `steam-tables.md` | `SteamTables.m`: the 16 fits, their thesis subroutines, validity ranges, the CRSTAT anchoring choice |
| 6 | `hydraulics.md` | `Hydraulics.m`: each flow-network solve as "circuit + quadratic"; feedwater, condensate, recirculation, air/gas networks |
| 7 | `turbomachinery.md` | `Turbomachinery.m`: extraction fits, induction motor torque, FP turbine |
| 8 | `heat-transfer.md` | `HeatTransfer.m`: furnace radiant balance, convective chain in flue-gas order |
| 9 | `vessels.md` | `VesselDynamics.m`: saturated-vessel mass/energy inversion (drum, deaerator) |
| 10 | `power-plant.md` | `PowerPlant.m`: evaluation order, the `sig` bus, states 1–22 & 47 derivative by derivative |
| 11 | `control-system.md` | `ControlSystem.m`: actuator commands, the 11 loops in code, limiters/transducers, states 23–46 |
| 12 | `simulator.md` | `Simulator.m`, `LoadProfile`, `GridProfile`: RK4 step, logging, scenarios; `InitialConditions` and trimming |
| 13 | `tests-and-app.md` | `test.run1..7`, `trim_operating_points.m`, the `PlantApp` dashboard architecture |
| 14 | `equation-to-code.md` | three worked walkthroughs: (a) drum pressure derivative, (b) swing equation incl. kjtre units, (c) reheat temperature loop from sensor to tilt |

Code excerpts are embedded as fenced blocks in the markdown (copied, with
file/line captions). Additionally, pages with `sourceFile:` front-matter
(a path, or a YAML list of paths) get a **view-source modal**: an icon
next to the page title opens the files' complete, Prism-highlighted (and
identifier-tooltipped) listings in a Bootstrap modal — tabbed by file
when the page covers several (e.g. `code/simulator` shows Simulator,
LoadProfile, GridProfile and InitialConditions). The listing is read from the repository **at build
time** — the one sanctioned exception to the "ui/ never reads src/"
isolation rule, accepted so the modal can never go stale (and so a
renamed model file fails the site build instead of silently lying).

## Milestones

1. **Scaffold** — root npm files, webpack + TS + Sass + Bootstrap, dev
   server, one hello page through the full pipeline (markdown → KaTeX →
   Prism → shell). Manifest + sidebar + pager working.
   **Done Aug 11, 2026** — including the abbr auto-wrap + lint, `@id`
   link checking, and stubs for all 44 pages wired into navigation
   (`ui/pipeline/gen-stubs.ts` creates sources for new manifest entries).
2. **Shell & blocks** — all `blocks.ts` containers styled; landing page;
   empty page stubs for all three sections wired into navigation.
   **Done Aug 11, 2026** — including `compare`/`figure` blocks and TOC
   scrollspy.
3. **Content: Basic Knowledge** — author pages 1–14.
   **Done Aug 11, 2026** — all 14 pages authored.
4. **Content: Power Plant** — author all 16 pages.
   **Done Aug 12, 2026.** (The planned SVG schematics were not made —
   pages shipped prose-first; revisit under milestone 6 if wanted.)
5. **Content: Code** — author all 14 pages.
   **Done Aug 12, 2026** — including the view-source modals
   (`sourceFile:` front-matter on the ten file pages).
6. **Polish & de-planning** — mobile pass, print styles, favicon,
   landing-page refinements. Plant schematic: a clickable inline-SVG
   overview diagram (every component links to its page) shipped on
   `plant/overview` Aug 12, 2026; per-component diagrams remain
   optional.
   De-planning **done Aug 12, 2026**: the `stub` flag, sidebar badges,
   shell stub-note and `gen-stubs.ts` are removed now that all 44 pages
   are authored.

Acceptance per content page: renders with no KaTeX errors, all `code-map`
links resolve, states/units consistent with `src/+model` as of the commit.

## Out of scope (for now)

- Client-side search (revisit with lunr.js once content stabilizes).
- Interactive simulations in the browser (would require porting the model
  to TS/WASM — a separate project).
- Deployment target: `npm run build` produces a static `dist/` that works
  from any static file server; hosting choice deferred.
