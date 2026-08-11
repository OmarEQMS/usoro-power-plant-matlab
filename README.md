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

## Entry points (`src/`)

| Script | What it does |
|---|---|
| `pba2_rk4.m` | **Recommended.** Thesis Test 1 (load ramp 100% → 77.5% at 15%/min) with **all 47 states integrated**. The full plant model is evaluated as a true derivative function `digpte47(t,x)` and advanced with classic fixed-step 4th-order Runge–Kutta at Ts = 0.1 s — the same scheme the thesis used (DYSYS routine, thesis p. 49). |
| `pba1_240814bk.m` | Original port of the same scenario using a *frozen-derivative* scheme: the loop evaluates the model once per 0.1 s sample, stores `xdot` in a global, and `ode45` integrates that constant — which makes the update exactly explicit Euler. Kept as reference. |
| `usoro_ss.m` | Steady-state / initial-condition explorer. |

Run from MATLAB with `src/` on the path:

```matlab
addpath src
pba2_rk4
```

or headless:

```
matlab -batch "addpath('src'); pba2_rk4"
```

The run produces six figures matching thesis Figures V.1 (pp. 65–70):
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

- `diginit100.m` / `diginit775.m` / `diginit50.m` — constants + initial state
  `x0` at 100% / 77.5% / 50% load (thesis p. 288 tables), sampling setup
  (`Ts`, `samples`).
- `const1.m`, `const2.m`, `const3.m` — plant parameter sets.
- `digpte47.m` — full plant + control derivative `f(t,x)` (47 states) and the
  logging row used for plots.
- `digpte.m` — legacy stub for the frozen-derivative scheme (returns global
  `dxdt`); only used by `pba1_240814bk.m`.
- Component modules (thesis Ch. II–III): steam/water property fits
  (`drstat`, `destat`, `shstat`, `rhstat`, `fwstat`, `cwstat`, `cpstat`,
  `fpstat`, `crstat`, `cnstat`, `lsstat`, `lwstat`, `rwstat`, `systat`,
  `rystat`, `hpstat`), flow networks (`shflow`, `fwflow`, `cwflow`, `rwflow`,
  `arflow`), heat transfer (`fnxfer`, `hxfer`), turbine extractions (`hpext`,
  `ipext`, `lpext`), machines (`torque`, `fpturb`), drum/deaerator balances
  (`drum`, `destmr`), and small helpers (`averag`, `xducer`, `limchk`,
  `check`).

See `docs/model.md` for the full state-vector table, the module ↔ thesis
correspondence, and a description of the eleven control loops; and
`docs/thesis_notes.md` for a standalone summary of the thesis itself (plant
description, modeling assumptions, control system, the seven emergency tests,
verification tables, and FORTRAN-listing landmarks).

## Verification

- Thesis Test 1 (Figures V.1, pp. 65–70): load ramp 100% → 77.5% (600 → 465 MW)
  at 15%/min applied from t = 10 s to t = 100 s; power output should track the
  ramp with ≈ 1% undershoot, throttle pressure should return to 2415 psia, and
  turbine speed should stay virtually constant at 377 rad/s (held by the
  generator's electromagnetic spring action).
- Steady-state values at 100% / 77.5% / 50% load are tabulated against
  manufacturer data in thesis Tables V.1–V.3 (agreement within 5%).
