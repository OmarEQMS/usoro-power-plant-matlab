# OOP model — architecture and usage

Object-oriented MATLAB rewrite of the Usoro 47th-order Digital Model, living
in the `src/+usoro` package. It supersedes the legacy flat-script code, which
is preserved in `src/old` and documented in [model_old.md](model_old.md); the
thesis background is in [thesis_notes.md](thesis_notes.md).

The rewrite is **numerically faithful by construction**: every equation and
constant is the same as the validated legacy `digpte47.m` (including the
`crstat` fix), reorganized — not re-derived. The validation section below
shows the OOP derivative is bit-for-bit identical to the legacy one.

## Package layout (`src/+usoro`)

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
| `Simulator` | handle | RK4 integration, logging, `f(t,x)` assembly | `pba2_rk4` main loop |

Plus `src/run_test1.m` (entry script reproducing thesis Figure V.1) and
`src/tools/gen_parameters.m` (regenerates `Parameters.m` from the legacy
constant scripts — run it if `src/old/const*.m` ever change).

## Data flow per derivative evaluation

```
Simulator.derivative(t, x)
  ├─ s   = StateVector.unpack(x)            named state struct
  ├─ ldc = LoadProfile.demand(t)            scenario input
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
run_test1          % thesis Test 1, ~3 min, six figures (Fig. V.1 pp. 65-70)
```

or programmatically:

```matlab
par = usoro.Parameters();
sim = usoro.Simulator(usoro.PowerPlant(par), ...
                      usoro.ControlSystem(par), ...
                      usoro.LoadProfile.test1());
res = sim.run(usoro.InitialConditions.at100(), 700);
% res.t, res.X (7001x47 states), res.log / res.logNames (1 Hz signal log)
```

## Extending

- **New scenario:** pass any `ldc(t)` handle —
  `usoro.LoadProfile(@(t) 5 - 0.025*max(0, min(t,120) - 10))` gives thesis
  Test 2's shape starting from 100%. Voltage/frequency disturbances (Tests
  5–6) need `nelec`/`velec` made time-dependent: change those `Parameters`
  properties between runs, or promote them into a profile analogous to
  `LoadProfile`.
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
