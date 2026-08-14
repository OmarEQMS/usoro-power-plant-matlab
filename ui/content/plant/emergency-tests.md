---
description: The thesis' seven emergency scenarios — what each one stresses, how to run it, what to watch, and how faithfully this model reproduces the published figures.
---

# The seven emergency tests

The thesis validated its model by running seven emergency scenarios and
publishing the trajectories (Figures V.1–V.11). This model implements
all seven as one-line entry points, `test.run1` … `test.run7`. This
page is the tour guide: each test's scenario, the component pages that
explain its physics, and an honest statement of how closely this
implementation matches the published figures.

::: why
The tests are the section's exam. If the pages so far did their job,
every trace in every test should now be *predictable*: you should be
able to say which loop rails, which machine sags, and where the plant
settles — before running it.
:::

## The load ramps (Tests 1–4)

All at 15%/min, the thesis' standard rate; the pure
[boiler-following](@plant/control-room) exercise — governor leads,
pressure dips, combustion repays.

| Test | Scenario | Watch | Match |
|---|---|---|---|
| 1 | 100% → 77.5% | power tracking, pressure recovery to 2415, drum [swell](@plant/waterwalls-drum) | quantitative (Fig. V.1) |
| 2 | 77.5% → 50% | same, deeper; [temperature schedules](@basics/control-practices) come off their clamps | quantitative (Fig. V.3) |
| 3 | 50% → 77.5% | load *increase* — harder: deeper pressure dip, slow convergence | quantitative (Fig. V.5) |
| 4 | 77.5% → 100% | the capability ceiling: governor saturates, air control near its rail | quantitative — climbs to rated and locks on (600.5 MW / 2415.0 psia at 700 s, main steam ≈1109 lb/s; Fig. V.7 ≈600 / 2415 / ≈1110) |

## The electrical emergencies (Tests 5–6)

The grid reaching into the plant through the
[auxiliary bus](@plant/generator) and the
[swing pair](@basics/generator-grid).

| Test | Scenario | Watch | Match |
|---|---|---|---|
| 5 | 30% line-voltage step drop | motor torque ∝ V²: [fans and pumps](@basics/rotating-machinery) sag and re-settle; steam side barely moves | quantitative (Fig. V.9) |
| 6 | frequency 60 → 56 Hz in 5 s | turbine dragged to 352 rad/s; [droop](@plant/loops-turbine) rails the governor; fans slow → [cross-limit](@plant/loops-combustion) caps fuel | quantitative (spike 563.7 vs ≈563 MW; settles 535.5 MW / 2115 psia vs thesis ≈537 / 2125) |

## The equipment loss (Test 7)

| Test | Scenario | Watch | Match |
|---|---|---|---|
| 7 | one FD+ID [fan pair lost](@plant/air-gas-path) at 100% | power dive and air-limited recovery; drum level's double deception; no run-back logic | tracks the figure's shape, *above* it (dip 410 vs ≈371 MW, recovery 448 vs ≈420) |

Two configuration notes reproduced from the thesis: gas recirculation
control is **deactivated** in Tests 6 and 7 (the thesis reports the
system settled poorly with it active), and Test 7 is simulated as two
phases stitched at the failure instant (`knfd`/`knid`: 2 → 1).

## Running them

```matlab
addpath src
res = test.run6;               % any of run1..run7
model.Simulator.plotStandard(res)
```

Tests 2–7 start from trimmed operating points — run
`src/tools/trim_operating_points.m` once first. The
[dashboard](@code/tests-and-app) runs the same scenarios interactively.

::: caution
The honest ledger, in one place. The trimmed operating points sit on
the thesis' published tables (77.5%: fuel 63.6 vs 63.3 lb/s, air 977
vs 972), and the 100% point holds indefinitely under constant
full-load demand (600.0 MW / 2415.0 psia). Tests 1–6 reproduce the
figures quantitatively; Tests 4 and 6 do so through the fan-curve
calibration `kfcal` (the fan ΔP coefficients carry ×1.10 so the air
path can deliver the 1230 lb/s the rated point needs — pinned by the
published steady states, see the
[air-gas path](@plant/air-gas-path)). The one residual is **Test 7**:
the fan-loss recovery lands ≈25–30 MW above Figure V.11. The
[model changelog](@plant/changelog) has the full residuals list and
the corrections behind today's numbers.
:::

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| the seven tests | `test.run1` … `test.run7` | `src/+test/` |
| scenario inputs | `LoadProfile.test1..4`, `GridProfile.test5/6` | `model.LoadProfile`, `model.GridProfile` |
| trimmed starting points | `ic775.mat`, `ic50.mat` | `src/tools/trim_operating_points.m` |
| standard plots | `Simulator.plotStandard(res)` | `model.Simulator` |
:::

One page remains in this section: the
[model changelog](@plant/changelog) — the corrections it took to make
every claim on this page true.
