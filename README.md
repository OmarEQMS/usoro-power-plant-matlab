# Usoro 47th-Order Drum Boiler–Turbine Power Plant Simulation

MATLAB implementation of the **Digital Computer Model** from:

> Patrick Benedict Usoro, *"Modeling and Simulation of a Drum Boiler-Turbine Power
> Plant Under Emergency State Control"*, M.S. thesis, MIT Dept. of Mechanical
> Engineering, May 1977 (advisor: Prof. D. N. Wormley).
> Available at [MIT DSpace, hdl:1721.1/16301](https://dspace.mit.edu/handle/1721.1/16301).

The model is **47th order**: 23 state variables describe the physical processes
(boiler, turbines, pumps, fans, feedwater train, generator) and 24 describe the
analog control system (thesis abstract, p. 4). The plant is a 600 MW drum
boiler–turbine unit operating in *boiler-following* control mode against an
infinite bus. All quantities are in English engineering units (lb/s, Btu/lb,
psia, ft·lbf, rad/s). All 47 states are integrated with classic fixed-step
RK4 at Ts = 0.1 s — the same scheme the thesis used (DYSYS routine, p. 49).

## Highlights

- **All seven thesis emergency tests** implemented and compared
  quantitatively against Figures V.1–V.11 (`docs/model.md`, per-test).
- **Trimmed operating points sit on the thesis's published steady-state
  tables** (77.5%: fuel 63.6 vs 63.3 lb/s, air 977 vs 972, drum 2602 vs
  2604 psia).
- **Transcription verified against the printed FORTRAN scan** — including
  three corrected slips (CRSTAT anchoring, `kjtre` units, HXFER mean
  specific heat) and a bit-for-bit equivalence harness against the
  archived first port (`deprecated/tools/validate_against_legacy.m`).
- **Interactive dashboard** (`src/run_ui.m`) and a **45-page
  documentation/learning website** (`ui/`, `npm run build`).
- **Fast:** a 700 s emergency run takes ≈18 s headless.

## Entry points

| Script | What it does |
|---|---|
| `src/+test/run1.m` | **Recommended.** Thesis Test 1: load ramp 100% → 77.5% at 15%/min. |
| `test.run2` / `test.run3` / `test.run4` | Thesis Tests 2–4: load ramps 77.5% → 50%, 50% → 77.5%, 77.5% → 100% at 15%/min. |
| `src/+test/run5.m` | Thesis Test 5: 30% line-voltage step drop at 77.5% load (auxiliary motors slow, controls compensate). |
| `src/+test/run6.m` | Thesis Test 6: grid frequency drop 60 → 56 Hz at 77.5% load (governor droop, air-limited output; uses the documented `kjtre` units correction, see `docs/model.md`). |
| `src/+test/run7.m` | Thesis Test 7: loss of one of two FD/ID fan pairs at 100% load (air-limited output, no run-back). |
| `src/run_ui.m` | **Interactive dashboard** (`PlantApp`): clickable plant schematic with per-component live charts, scenario selection (Tests 1–7 / steady hold), play/pause/reset, speed control, and a run-time selector (350/700/1400/2800 s — extend a finished run in place). |

Tests 2–7 (and the dashboard's non-Test-1 scenarios) need the trimmed
operating points: run `src/tools/trim_operating_points.m` once first.

Run from MATLAB:

```matlab
addpath src
test.run1
```

or headless:

```
matlab -batch "addpath('src'); test.run1"
```

The run produces six figures matching thesis Figure V.1 (pp. 65–70):
power/speed/pressure, control demands, drum & deaerator levels, steam
enthalpies, and auxiliary machine speeds.

## Source layout

- `src/+model/` — the model: `Parameters` (generated constants),
  `StateVector`, `InitialConditions`, `SteamTables`, `Hydraulics`,
  `Turbomachinery`, `HeatTransfer`, `VesselDynamics`, `PowerPlant`,
  `ControlSystem`, `LoadProfile`, `GridProfile`, `Simulator`.
  Architecture, usage and extension guide: `docs/model.md`.
- `src/+test/run1.m` … `src/+test/run7.m` — entry scripts (thesis Tests 1–7,
  except the coordinated-mode variants).
- `src/tools/trim_operating_points.m` — generates the trimmed 77.5% and 50%
  operating points (`ic775.mat`, `ic50.mat`).
- `src/PlantApp.m`, `src/run_ui.m` — the interactive dashboard.
- `deprecated/` — archived pre-OOP implementation and its documentation and
  tools. Not needed to run anything above; see `deprecated/README.md`.

Documentation index:

- `docs/model.md` — architecture, state vector, control loops, data flow,
  per-test validation results, known quantitative offsets, how to extend,
  and the maintainer workflow (verification oracles, the fix-and-re-trim
  loop).
- `docs/thesis_notes.md` — standalone thesis summary (plant description,
  modeling assumptions, control system, the seven emergency tests,
  verification tables, FORTRAN-listing landmarks).
- `docs/next_steps.md` — open investigations (the Test 4 air-margin limit
  cycle chief among them) and planned improvements.
- `docs/ui.md` — the documentation/learning website: pipeline
  architecture, how to build and add pages, authoring conventions,
  verification checklist, and gotchas. Source under `ui/`, built site
  under `dist/`.

**Website content policy:** the site's pages (`ui/content/`) describe the
*current* model only — no "previously the model did X" framing. All
correction history (transcription fixes, their symptoms and root causes,
remaining residuals) lives on the site's dedicated changelog page,
`ui/content/plant/changelog.md`; new fixes get an entry there, not a
historical aside on a component page. The repository docs above are the
engineering audit trail and do keep their history.

## Verification

- Thesis Test 1 (Figures V.1, pp. 65–70): load ramp 100% → 77.5% (600 → 465 MW)
  at 15%/min applied from t = 10 s to t = 100 s; power output tracks the
  ramp with ≈ 1% undershoot, throttle pressure returns to 2415 psia, and
  turbine speed stays virtually constant at 377 rad/s (held by the
  generator's electromagnetic spring action).
- Steady-state values at 100% / 77.5% / 50% load are tabulated against
  manufacturer data in thesis Tables V.1–V.3 (agreement within 5%).
- Per-test quantitative comparisons against Figures V.1–V.11 are in
  `docs/model.md`, including the documented air-margin residual on
  Tests 4 and 6.
