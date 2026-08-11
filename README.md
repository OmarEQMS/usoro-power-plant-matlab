# Usoro 47th-Order Drum Boiler–Turbine Power Plant Simulation

MATLAB replication of the **Digital Computer Model** from:

> Patrick Benedict Usoro, *"Modeling and Simulation of a Drum Boiler-Turbine Power
> Plant Under Emergency State Control"*, M.S. thesis, MIT Dept. of Mechanical
> Engineering, May 1977 (advisor: Prof. D. N. Wormley).
> Available at [MIT DSpace, hdl:1721.1/16301](https://dspace.mit.edu/handle/1721.1/16301).

The model is **47th order**: 23 state variables describe the physical processes
(boiler, turbines, pumps, fans, feedwater train, generator) and 24 describe the
analog control system (thesis abstract, p. 4). The plant is a 600 MW drum
boiler–turbine unit operating in *boiler-following* control mode against an
infinite bus. All quantities are in English engineering units (lb/s, Btu/lb,
psia, ft·lbf, rad/s).

## Entry points

| Script | What it does |
|---|---|
| `src/run_test1.m` | **Recommended.** Thesis Test 1 (load ramp 100% → 77.5% at 15%/min) on the **OOP model** (`src/+usoro` package): all 47 states integrated with classic fixed-step RK4 at Ts = 0.1 s — the same scheme the thesis used (DYSYS routine, p. 49). Validated bit-for-bit against the legacy model. |
| `src/old/pba2_rk4.m` | Legacy flat-script version of the same run: full model as derivative function `digpte47(t,x)` + RK4. |
| `src/old/pba1_240814bk.m` | Original port using a *frozen-derivative* scheme (equivalent to explicit Euler), which forced the speed states to be hardcoded. Kept as reference. |
| `src/old/usoro_ss.m` | Steady-state / initial-condition explorer (legacy). |

Run from MATLAB:

```matlab
addpath src          % OOP model (add src/old instead for the legacy scripts)
run_test1
```

or headless:

```
matlab -batch "addpath('src'); run_test1"
```

The run produces six figures matching thesis Figure V.1 (pp. 65–70):
power/speed/pressure, control demands, drum & deaerator levels, steam
enthalpies, and auxiliary machine speeds.

## Why `pba1` had hardcoded speeds — and how `pba2` removes them

In `pba1_240814bk.m` the feed pump turbine speed (`nfp`, state 1) and the
turbine–generator speed (`ntr`, state 16) had their derivatives hardcoded to
zero. This was **not** a modeling deviation — both equations appear in the
code, commented out, and match the thesis (pp. 152–153, 159–160) exactly. It
was a numerical-stability workaround:

- The turbine–generator is modeled as an **undamped** swing pair
  (thesis pp. 152–153): `dntr/dt = (mwtro − mwgn)/(ntr·kjtre)` with generator
  power `mwgn = kmwr·2·sin(delta)` and `d(delta)/dt = ntr − nelec`. Damping is
  deliberately ignored in the thesis ("the damping effect is ignored compared
  to the damping effect present in the mechanical system"). The pair is a
  marginally stable oscillator at ≈ 1.8 rad/s.
- The frozen-derivative scheme is mathematically **explicit Euler**, and
  explicit Euler is unconditionally unstable for an undamped oscillator — the
  swing mode grows a few % per step and wrecks the run. Freezing `ntr` (and,
  defensively, `nfp`) suppressed the divergence.
- The thesis did not have this problem because DYSYS used **4th-order
  Runge–Kutta**, whose stability region includes the segment of the imaginary
  axis up to |ωh| = 2√2; at ωh ≈ 0.18 RK4 is (weakly) stable and adds only
  tiny numerical damping.

`pba2_rk4.m` therefore restructures the model into a genuine derivative
function (`digpte47.m`, the algebraic body of `pba1` transcribed verbatim,
with `xdot(1)` and `xdot(16)` restored) and integrates it with RK4, matching
the thesis numerics. The load-demand ramp is computed from `t` inside
`digpte47` so the function is a pure `f(t,x)`.

### The `crstat.m` transcription bug

Un-freezing `nfp` exposed a second, independent defect: `crstat.m` computed
the IP-turbine/cross-over outlet enthalpy as `ho = hi − ef·(h1 − hi)`
(anchored at the *isentropic* enthalpy `hi`) instead of the thesis relation
`ho = h1 − ef·(h1 − hi)` (thesis p. 149; same form correctly used in
`hpstat.m`). The thesis FORTRAN line is OCR-ambiguous (`H1` vs `HI`), which is
how the slip crept in. Evidence that the corrected form is right:

- With the fix, the feed pump turbine torque balance closes at the thesis 100%
  initial conditions to four significant digits (steam demand needed: 38.42
  lb/s; thesis IC value: 38.4212 lb/s). With the bug, the drive torque was
  half the load and `nfp` crashed, draining the drum.
- Cross-over conditions become physically sensible: 173 psia / 709 °F, versus
  126 psia / 367 °F (below saturation!) with the bug.
- The bug was masked in `pba1` because (a) `nfp` was frozen, and (b) the
  IP-power surplus and LP-power deficit it produced nearly cancel in total
  power output.

## Source layout

- `src/+usoro/` — the **OOP model** (current): `Parameters` (generated
  constants), `StateVector`, `InitialConditions`, `SteamTables`,
  `Hydraulics`, `Turbomachinery`, `HeatTransfer`, `VesselDynamics`,
  `PowerPlant`, `ControlSystem`, `LoadProfile`, `Simulator`. Architecture,
  usage and extension guide: `docs/model_oop.md`.
- `src/run_test1.m` — entry script (thesis Test 1).
- `src/tools/gen_parameters.m` — regenerates `+usoro/Parameters.m` from the
  legacy constant scripts.
- `src/old/` — the complete legacy flat-script model (entry points
  `pba1_240814bk.m`, `pba2_rk4.m`, derivative `digpte47.m`, init/constant
  scripts, and ~30 component functions). Documented in `docs/model_old.md`.

Documentation index:

- `docs/model_oop.md` — OOP architecture, data flow, validation, how to extend.
- `docs/model_old.md` — legacy structure: full state-vector table, module ↔
  thesis correspondence, the eleven control loops, the frozen-speed history
  and the `crstat` fix.
- `docs/thesis_notes.md` — standalone thesis summary (plant description,
  modeling assumptions, control system, the seven emergency tests,
  verification tables, FORTRAN-listing landmarks).

## Verification

- Thesis Test 1 (Figures V.1, pp. 65–70): load ramp 100% → 77.5% (600 → 465 MW)
  at 15%/min applied from t = 10 s to t = 100 s; power output should track the
  ramp with ≈ 1% undershoot, throttle pressure should return to 2415 psia, and
  turbine speed should stay virtually constant at 377 rad/s (held by the
  generator's electromagnetic spring action).
- Steady-state values at 100% / 77.5% / 50% load are tabulated against
  manufacturer data in thesis Tables V.1–V.3 (agreement within 5%).
