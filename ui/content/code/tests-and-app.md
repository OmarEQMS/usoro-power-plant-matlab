---
description: The seven test entry points, the trim tool, and the interactive dashboard — everything built on top of the Simulator API.
sourceFile:
  - src/+test/run7.m
  - src/+test/run1.m
  - src/tools/trim_operating_points.m
  - src/PlantApp.m
---

# Tests and the dashboard

Above the [Simulator API](@code/simulator) sit the things you actually
launch: seven test functions, one trim tool, and an interactive
dashboard. None of them contain model logic — they are *compositions*
of the API, which is exactly what makes them worth reading as examples.

::: why
When you write your own experiment, you will copy one of these. The
test runners show the canonical assembly; `run7` shows how to handle a
mid-run configuration change; the dashboard shows how to drive the
model interactively without touching its internals.
:::

## The seven runners

Each `test.runN` is the same five moves: build `Parameters`, build the
machines, pick the scenario profile(s), load the starting state, run —
then plot. The variations are the scenarios themselves
([the tests page](@plant/emergency-tests)):

- **run1–run4:** `LoadProfile.test1..4`, nominal grid; run1 starts
  from `InitialConditions.at100()`, the rest from the trimmed points.
- **run5, run6:** constant load, `GridProfile.test5/test6`; run6 also
  sets `gasRecircEnabled = false`
  ([as the thesis did](@code/control-system)).
- **run7:** the instructive one — open its source with the icon above.

## run7: changing the plant mid-run

Losing a fan pair means the *configuration constants* `knfd`/`knid`
change from 2 to 1 — and [Parameters](@code/parameters) is immutable
data inside constructed machines. The runner's answer is honest:
**two simulators, stitched.**

Phase one runs the healthy plant to the failure instant; its final
state becomes phase two's initial state, and phase two's machines are
built from a *second* `Parameters` copy with one fan pair. The physics
of the handoff is free: the state vector is
[stored mass, energy and momentum](@basics/state-variables) — all
continuous through the event — while the algebra (flows, pressures)
legitimately jumps. The same pattern serves any discrete event: valve
failures, heater trips, changed constants.

## The trim tool

`src/tools/trim_operating_points.m` — covered as the
[API worked example](@code/simulator) — regenerates
`ic775.mat`/`ic50.mat`. Run it once per fresh clone (Tests 2–7 need
it), and rerun it after *any* change to the model's physics: trimmed
states are equilibria of a specific $f$, and editing the model quietly
invalidates them.

## The dashboard

`run_ui` opens `PlantApp` — a programmatic `uifigure` (no binary
`.mlapp`, so it diffs like code): a clickable plant schematic where
each block opens live charts, a scenario dropdown covering the seven
tests, play/pause/speed controls, a run-time selector (350/700/1400/
2800 s; scenarios load their thesis default, and extending it — even
after a run finishes — grows the buffers in place so Play just
continues), and an inputs window showing what the scenario is doing
to the plant. Architecture notes for anyone extending it:

- a MATLAB `timer` drives `Simulator.step` (the
  [public single-step method](@code/simulator)); the speed selector
  sets steps per tick;
- every step appends one sample (states + `sig` + `u`) to a
  preallocated ring buffer; chart windows redraw from the buffer, so
  charts opened mid-run show full history;
- a component registry maps each schematic block to its four charted
  signals — adding a block or changing signals is a registry edit;
- Test 7's stitch is handled exactly as in `run7`, at t = 10 s.

::: caution
The runners plot and return; they assert nothing. "Test" here means
*thesis test scenario*, not unit test — the pass/fail judgment against
the thesis figures is [made by eye](@plant/emergency-tests), and the
model's regression safety net lives elsewhere (an archived
equivalence harness against the pre-OOP implementation).
:::

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| the runners | `test.run1` … `test.run7` | `src/+test/` |
| the stitch pattern | `run7` two-phase assembly | `src/+test/run7.m` |
| trim tool | `trim_operating_points.m` | `src/tools/` |
| dashboard | `PlantApp.m`, launcher `run_ui.m` | `src/` |
:::

Next — the finale: [Equation to code, three
walkthroughs](@code/equation-to-code).
