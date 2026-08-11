# OOP model — architecture and usage

Object-oriented MATLAB rewrite of the Usoro 47th-order Digital Model, living
in the `src/+model` package. It supersedes the legacy flat-script code, which
is preserved in `src/old` and documented in [model_old.md](model_old.md); the
thesis background is in [thesis_notes.md](thesis_notes.md).

The rewrite is **numerically faithful by construction**: every equation and
constant is the same as the validated legacy `digpte47.m` (including the
`crstat` fix), reorganized — not re-derived. The validation section below
shows the OOP derivative is bit-for-bit identical to the legacy one.

## Package layout (`src/+model`)

| Class | Kind | Role | Replaces (src/old) |
|---|---|---|---|
| `Parameters` | value, **generated** | all 306 plant/control constants as properties, thesis symbol names | `diginit100` (constants part), `const1`–`const3` |
| `StateVector` | static | state indices, names, `unpack(x)` → named struct | the `x0(i)` equivalence blocks |
| `InitialConditions` | static | canonical 100%-load state (thesis p. 288) | `diginit100` (state part) |
| `SteamTables` | static | 16 water/steam property fits | `drstat`, `destat`, `shstat`, `rhstat`, `fwstat`, `cwstat`, `cpstat`, `fpstat`, `hpstat`, `crstat`, `cnstat`, `lsstat`, `lwstat`, `rwstat`, `systat`, `rystat` |
| `Hydraulics` | static | closed-form flow-network solvers | `shflow`, `fwflow`, `cwflow`, `rwflow`, `arflow` |
| `Turbomachinery` | static | extraction fits, motor and FP-turbine torque | `hpext`, `ipext`, `lpext`, `torque`, `fpturb` |
| `HeatTransfer` | static | furnace radiant balance, convective exchangers | `fnxfer`, `hxfer` |
| `VesselDynamics` | static | saturated-vessel balances, deaerator steam | `drum`, `destmr` |
| `PowerPlant` | handle | physical process model: algebra + states 1–22, 47 | the process section of `digpte47` |
| `ControlSystem` | handle | actuator transducers + the 11 loops: states 23–46 | the control section of `digpte47`; `xducer`, `limchk`, `check` |
| `LoadProfile` | value | LDC demand `ldc(t)`; swappable scenarios | the hardcoded ramp in `digpte47` |
| `GridProfile` | value | grid frequency `nelec(t)` and voltage `velec(t)`; enables the electrical emergency tests | (grid was fixed in the legacy code) |
| `Simulator` | handle | RK4 integration, logging, `f(t,x)` assembly | `pba2_rk4` main loop |

Plus the `src/+test` package — `test.run1` … `test.run7`, one function per
thesis test, each returning the simulation results — the dashboard
(`src/PlantApp.m`, launcher `src/run_ui.m`) and two tools:
`src/tools/gen_parameters.m` (regenerates `Parameters.m` from the legacy
constant scripts — run it if `src/old/const*.m` ever change) and
`src/tools/trim_operating_points.m` (generates the trimmed 77.5% and 50%
operating points `+model/ic775.mat` / `+model/ic50.mat` needed by
Tests 2–7).

## Data flow per derivative evaluation

```
Simulator.derivative(t, x)
  ├─ s   = StateVector.unpack(x)            named state struct
  ├─ ldc = LoadProfile.demand(t)            scenario input
  ├─ g   = GridProfile at t                 nelec(t), velec(t)
  ├─ u   = ControlSystem.actuatorCommands(s)
  │        demand states (35-43, 46) ── xducer ──> valve/vane areas,
  │        fuel, spray, gas-recirc and FP-turbine steam flows
  ├─ [xdotPhys, sig] = PowerPlant.evaluate(s, u)
  │        thermoStates → steamPathAndTurbines → waterSide
  │        → mixingAndHeaters → airGasSide → effectiveMasses
  │        → vesselBalances → machines → physicalDerivatives
  │        (sig accumulates every intermediate under its thesis name)
  ├─ xdotCtrl = ControlSystem.derivatives(s, u, sig, ldc)
  │        boiler master → air → fuel → furnace pressure → gas recirc
  │        → FP turbine → feedwater → deaerator level → reheat temp
  │        → superheat temp → turbine/governor
  └─ xdot = xdotPhys + xdotCtrl             (disjoint index ranges)
```

The `sig` struct is the plant "signal bus": the control loops read their
measured variables from it (`psso`, `war`, `pfn`, `pfvd`, `wfw`, `p1st`,
`xdrw`, `pdrs`, `prho`, `wcw`, `xdew`, `trho`, `whp`, `tsso`, `mwtro`, …),
and the logger picks its columns from it.

## Running

```matlab
addpath src
test.run1          % Test 1: load ramp 100% -> 77.5%   (Fig. V.1,  pp. 65-70)
test.run2          % Test 2: load ramp 77.5% -> 50%    (Fig. V.3,  pp. 75-80)
test.run3          % Test 3: load ramp 50% -> 77.5%    (Fig. V.5,  pp. 85-90)
test.run4          % Test 4: load ramp 77.5% -> 100%   (Fig. V.7,  pp. 95-100)
test.run5          % Test 5: 30% voltage drop          (Fig. V.9,  pp. 105-110)
test.run6          % Test 6: frequency drop 60->56 Hz  (Fig. V.10, pp. 111-116)
test.run7          % Test 7: loss of an FD/ID fan pair (Fig. V.11, pp. 117-122)
```

Tests 2–7 need the trimmed operating points — run
`src/tools/trim_operating_points.m` once first (~2 min) if
`+model/ic775.mat` / `+model/ic50.mat` are missing. Custom load ramps:
`model.LoadProfile.ramp(ldc0, ldc1, tStart, rate)` (`ldc` = 5 × load
fraction; thesis rate 15%/min = 0.0125 V/s is the default).

## Interactive dashboard (`PlantApp`)

`run_ui` (or `app = PlantApp();`) opens an interactive dashboard: a
schematic of the plant whose component blocks are clickable — each opens a
window with four live charts of that component's key variables — plus a
scenario dropdown (thesis Tests 1–7 or a steady 100% hold),
Play/Pause/Reset, an **Inputs** button (live charts of what the plant is
receiving: LDC load demand, grid frequency, line voltage, operating
fan-pair count) and a speed selector (1×/5×/20×/Max real time). The status
bar shows t, power output and throttle pressure live.

![Dashboard](img/ui_main.png)
![Drum live charts](img/ui_drum_chart.png)
![Plant inputs during Test 6](img/ui_inputs.png)

Implementation notes (`src/PlantApp.m`, programmatic `uifigure` app — no
binary `.mlapp`):

- The simulation advances through `model.Simulator.step` (the same RK4
  scheme as `run`, exposed as a public single-step method), driven by a
  MATLAB `timer`; the speed selector sets steps per tick.
- Every step, one signal sample (states + `sig` bus + actuators) is stored
  in a preallocated buffer; open chart windows redraw from the buffer at
  the UI rate, so charts can be opened mid-run and show full history.
- The component registry inside `PlantApp` maps each diagram block to its
  four charted signals — extend it to add blocks or change signals.
- Test 7's fan-count step is handled as two simulator phases switched at
  t = 10 s, exactly as in `test.run7`.

Or programmatically:

```matlab
par = model.Parameters();
sim = model.Simulator(model.PowerPlant(par), ...
                      model.ControlSystem(par), ...
                      model.LoadProfile.test1());
res = sim.run(model.InitialConditions.at100(), 700);
% res.t, res.X (7001x47 states), res.log / res.logNames (1 Hz signal log)
```

## Extending

- **New scenario:** pass any `ldc(t)` handle —
  `model.LoadProfile(@(t) 5 - 0.025*max(0, min(t,120) - 10))` gives thesis
  Test 2's shape starting from 100%. Grid disturbances take a
  `model.GridProfile` (4th `Simulator` argument): `test5()`, `test6()`, or
  any pair of `nelec(t)`/`velec(t)` handles.
- **Parameter studies:** `Parameters` is a value class — copy and modify:
  `par2 = par; par2.kjtre = 2*par.kjtre;` then build a new plant with it.
- **Control experiments:** subclass `ControlSystem` and override
  `derivatives` (or a future extracted per-loop method); the plant is
  untouched. The rate-feedforward stubs (`fc2dv`, `fcp1st`, `fctrho`,
  `fcxgg` — the legacy "falta" items) are public properties, so a subclass
  or script can supply them.
- **Different integrator:** `Simulator.derivative(t,x)` is public and
  side-effect-free — hand it to `ode45`/`ode15s` directly if wanted
  (`[tt,xx] = ode45(@(t,x) sim.derivative(t,x), [0 700], x0)`), keeping in
  mind the limiters make the RHS non-smooth.

## Conventions and design decisions

- **Thesis names preserved.** Constants (`kjtre`, `kupsgm`, …), signals
  (`wdrs`, `qwwgm`, …) and states keep their thesis/FORTRAN names so the
  code cross-references directly against the thesis and `model_old.md`.
  Classes and methods follow standard MATLAB style (PascalCase classes,
  camelCase methods).
- **`Parameters` is generated, not hand-typed.** 306 constants transcribed
  by hand would be a typo lottery; `tools/gen_parameters.m` extracts them
  from the legacy scripts, keeping one source of truth.
- **Subroutine-local fit coefficients stay local** (in `Hydraulics`,
  `HeatTransfer`, etc.) exactly as they are subroutine-local in the thesis
  FORTRAN — they are curve-fit internals, not tunable plant parameters.
- **`PowerPlant` is one class, not eight component objects.** The process
  algebra is a single tightly coupled system solved in a fixed order; the
  subsystem structure is expressed as private methods over the shared `sig`
  bus. Splitting it into independently instantiated component objects would
  add indirection without decoupling anything real.
- **RK4 at 0.1 s** replicates the thesis integration (DYSYS) and is stable
  for the undamped turbine-generator swing pair — see
  [model_old.md](model_old.md) for the frozen-speed history behind this.

## Load-ramp tests (thesis Tests 2, 3, 4)

All at the thesis 15%/min rate, starting from the trimmed operating points:

- **Test 2** (`test.run2`, 77.5% → 50%): matches Figure V.3 closely —
  power settles 299.9 MW with a 294 MW undershoot (thesis ≈298/295),
  throttle peaks 2441 → returns 2416 psia (thesis 2437 → 2415), main steam
  flow ends 529 lb/s (thesis ≈530).
- **Test 3** (`test.run3`, 50% → 77.5%): power overshoots to 471.4 MW
  (thesis ≈472) and settles 464; the throttle-pressure dip is deeper than
  the thesis (2218 vs ≈2354 psia) and still converging at 700 s —
  consistent with the thesis observation that load *increases* are harder.
- **Test 4** (`test.run4`, 77.5% → 100%): the thesis already calls this
  run only "fairly well behaved" (signals saturate, power lags demand).
  In this model the effect is stronger: governor and air demands rail at
  5 V, fuel is held back by the air cross-limit, and the plant tops out
  near **485 MW at ≈1906 psia** instead of recovering to 600 MW / 2415.
  Mechanism: the crstat-fixed heat balance runs more gas recirculation
  (reheat-side), which consumes ID-fan capacity, so the air ceiling binds
  below rated firing when ramping up. See "Known quantitative offsets"
  below.

![Test 7 overview](img/test7_overview.png)

## Fan-loss test (thesis Test 7)

`test.run7`: at 100% load, one of the two FD+ID fan pairs is lost at
t = 10 s (no Unit Run-Back; gas recirculation off as in the thesis run).
The fan count is a configuration constant (`knfd`/`knid`), so the script
stitches two phases at t = 10 s. Results track Figure V.11 closely:

| Variable | This model | Thesis Fig. V.11 |
|---|---|---|
| Power dip / recovery | 364.7 → 419.2 MW | ≈371 → ≈420 |
| Throttle pressure min / end | 1531 / 1679 psia | ≈1560 / ≈1700 |
| Main steam flow min / end | 685 / 749 lb/s | ≈690 / ≈770 |
| Air control / governor | rail at 5 V | rail at 5 V |
| Turbine speed | flat 377 | flat 377 |

## Known quantitative offsets

The corrected model (crstat fix) burns more fuel and runs more gas
recirculation at partial load than the thesis run (e.g. fuel demand ≈4.18 V
at 77.5% vs ≈3.81 in Figure V.9), so it sits closer to the air/fuel signal
rails. Tests that push toward maximum capability (4, 6, 7) therefore
saturate earlier or settle deeper than the thesis figures, while their
transient shapes and mechanisms match. Tests 1, 2, 3 and 5, which stay
inside the control range, match quantitatively. The investigation plan for
this offset is in [next_steps.md](next_steps.md).

## Electrical emergency tests (thesis Tests 5 and 6)

Both start from the trimmed 77.5% operating point
(`model.InitialConditions.at775()`, generated by `src/tools/trim_operating_points.m`:
Test-1 ramp + 1300 s settling + damped swing settling + exact pinning of the
swing pair; worst residual ≈ 7e-4).

**Test 5** (`test.run5`): 30% step drop in line voltage at t = 10 s
(4160 → 2912 V). Reproduces thesis Figure V.9 closely — motor torque falls
with voltage², the auxiliaries slow, the controls compensate, the steam side
barely moves:

| Variable | This model | Thesis Fig. V.9 |
|---|---|---|
| Condensate pump speed | 186.7 → 184.2 rad/s in ~10 s | 186.7 → 184.2 |
| Recirculation pump speed | 187.1 → 185.45 in ~10 s | 187 → 185.45 |
| FD fan speed | 62.3 → 61.6, ~100 s | 62.3 → 61.7, ~100 s |
| ID fan speed | 93.2 → 91.3, slow ~150 s | 93.25 → 91.9, ~150 s |
| Power / throttle pressure | flat 465 MW / 2415 psia | flat |
| Feed pump speed | flat (steam-driven) | flat |

![Test 5 auxiliary speeds](img/test5_aux_speeds.png)

**Test 6** (`test.run6`): line frequency ramps 60 → 56 Hz at 0.8 Hz/s from
t = 10 s; gas recirculation control deactivated as in the thesis run.
Turbine speed drops with the grid to 351.9 rad/s exactly as in Figure V.10;
governor and air-flow controls rail at 5 V (as in the thesis); the fast
transient matches quantitatively (power spike 562 MW vs ≈563; steam-flow
peak 1043 lb/s vs ≈1040). The sustained depression is deeper than the
thesis (settles ≈470 MW at ≈1857 psia vs 537 MW at 2125 psia) because this
model's 77.5% operating point runs closer to the air/fuel signal rails
(the crstat-fix heat-balance shift), so the frequency-limited fans cap
firing at a lower level. Note the boiler-master integrator state (`c3md`)
winds up without bound while the pressure set point is unreachable — its
*limited* copy is what acts; the legacy model behaves identically.

![Test 6 overview](img/test6_overview.png)

## The kjtre units correction

The thesis data deck lists the turbine–generator inertia `KJTRE = 625000`.
Taken as slug·ft² (consistent with torque in lbf·ft), that implies an
inertia constant H ≈ 88 s — an order of magnitude beyond any real
turbine-generator (typical 3–9 s). Read instead as the vendor-style WR² in
lbm·ft² and divided by g_c = 32.174, it gives H ≈ 2.7 s — physical.

The decisive evidence is thesis Test 6 itself: with the as-listed value the
swing pair cannot track the 0.8 Hz/s grid ramp (required deceleration
≈ 5 rad/s² against a pull-out capability of ≈ 2.3 rad/s²), the generator
pole-slips, the governor slams shut and the simulated plant collapses —
while thesis Figure V.10 shows a clean ride-through. With `kjtre/32.174`
the model reproduces the thesis figure's behavior. Tests 1 and 5 are
insensitive to `kjtre` (verified: identical results), except that Test 1's
turbine-speed trace becomes even flatter (±0.01 rad/s) and the former slow
swing-envelope growth disappears (the faster swing mode falls in RK4's
strongly damped region).

The correction is applied in `tools/gen_parameters.m` (and so survives
regeneration); the *other* rotor inertias (`kjfpe`, `kjrp`, `kjcp`, `kjfd`,
`kjid`) are kept as listed — Test 5 validates their values directly through
the pump/fan slow-down time constants. The legacy code in `src/old` keeps
the thesis-as-listed value.

## Validation

Against the legacy `digpte47.m` (itself validated against thesis Figure V.1
and Tables V.1–V.2, see `model_old.md`):

- **Pointwise:** `Simulator.derivative(t,x)` vs `digpte47(t,x)` at five
  (t, x) combinations chosen to exercise both sides of every flow branch
  (governor closed → `wtv < kwtv` steam-source switch; large burner tilt →
  gas-recirculation deadband): **max relative difference 0.0 — bit-for-bit
  identical** on all 47 derivative components.
- **Full 700 s Test 1 run** with identical RK4 stepping: bit-for-bit
  identical final state.

| Check | Result |
|---|---|
| Derivative, 5 test points × 47 components | exact (max rel. diff 0.0) |
| Final state after 7000 RK4 steps (28,000 evaluations) | exact (max rel. diff 0.0) |
| Runtime, full 700 s Test 1 | OOP 18.4 s vs legacy 217.3 s (~12× faster — the legacy `digpte47` re-runs the constant scripts on every call; `Parameters` is constructed once) |

These A/B checks were run before the `kjtre` correction was adopted; with it,
the only difference from the legacy derivative is `xdot(16)`, scaled by
exactly the documented factor 32.174 (all other 46 components remain
identical).
