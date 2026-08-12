---
description: The physical plant as one class — the nine-stage evaluation pipeline, the write-once sig bus, and the 24 physical derivatives grouped by kind.
sourceFile: src/+model/PowerPlant.m
---

# PowerPlant.m

The largest class in the model, and deliberately *one* class: the
entire physical plant — steam path, water side, gas side, machines —
evaluated as a single tightly-coupled algebra. Everything the previous
five pages cataloged ([fits](@code/steam-tables),
[networks](@code/hydraulics), [machines](@code/turbomachinery),
[heat](@code/heat-transfer), [vessels](@code/vessels)) gets *called
from here*, in an order that is itself part of the model.

::: why
Splitting the plant into component objects would decouple nothing —
every subsystem reads pressures and flows that other subsystems
compute. The class expresses the real structure instead: one shared
signal bus, one fixed evaluation order, private methods as chapter
headings. Understand the order and the file reads like the plant
schematic.
:::

## One public method

```matlab
[xdot, sig] = plant.evaluate(s, u, g)
```

Named states in (`s`, from [StateVector](@code/state-vector)), actuator
commands in (`u`, from [ControlSystem](@code/control-system)), grid
conditions in (`g`); the 23 physical derivatives and the complete
[sig bus](@code/conventions) out. Pure function — no stored plant
state, everything rebuilt per call.

## The nine stages

`evaluate` chains private methods, each filling its slice of `sig`:

| Stage | Fills in | Leans on |
|---|---|---|
| `thermoStates` | properties at every stored volume | [SteamTables](@code/steam-tables) |
| `steamPathAndTurbines` | steam flows, extractions, cylinder powers | [flow laws](@basics/fluid-flow), [Turbomachinery](@code/turbomachinery) |
| `waterSide` | feedwater / condensate / recirc loops | [Hydraulics](@code/hydraulics) |
| `mixingAndHeaters` | heater balances, spray mixes | SteamTables mixers |
| `airGasSide` | gas path, furnace, four-bank chain | [airGas](@code/hydraulics), [HeatTransfer](@code/heat-transfer) |
| `effectiveMasses` | fluid + metal thermal masses | [effective-mass idea](@basics/mass-energy-balances) |
| `vesselBalances` | drum / deaerator imbalances + joint solves | [VesselDynamics](@code/vessels) |
| `machines` | motor and FP-turbine torques, levels, `p1st` | Turbomachinery |
| `physicalDerivatives` | assembles `xdot` | everything above |

The order is a **topological sort of the physics**: properties must
exist before flows can be computed, flows before heat transfer, heat
before imbalances, everything before derivatives. Reordering stages is
not a refactor — it is using values before they are written, and the
write-once bus makes such a mistake loud (an unset struct field errors
immediately).

## The derivative roster

`physicalDerivatives` writes 24 entries, all patterns you have met:

- **Torque balances** (1, 6, 16, 17, 21, 22) — the
  [rotor law](@basics/rotating-machinery), including the
  [swing equation](@basics/generator-grid);
- **Mass balances** (5, 8, 10, 12, 13, 15, 20) — density states,
  `(in − out)/volume`;
- **Energy balances** (2, 3, 9, 11, 14, 18) — enthalpy states,
  `(Σwh + q)/mₑ`;
- **Metal temperature** (7) — radiant in, boiling out;
- **Vessel pairs** (4/5, 19/20) — from the
  [joint solves](@code/vessels);
- **Angle** (47) — `ntr − nelec`.

Open the [source](@code/power-plant) (the icon by the title) at
`physicalDerivatives` and read them against this list: each line is
one balance from this site's first section.

::: caution
`evaluate` computes plant physics for whatever `u` it is given —
including commands beyond hardware limits. The clamping happens in
`ControlSystem.actuatorCommands`, *before* the plant sees anything.
Bypass the control system (custom experiments) and you inherit its
job of keeping commands physical.
:::

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| entry point | `evaluate(s, u, g)` | `src/+model/PowerPlant.m` |
| the stages | private methods, in call order | `src/+model/PowerPlant.m` |
| the bus | `sig.*`, write-once | all stages |
| derivative assembly | `physicalDerivatives` | `src/+model/PowerPlant.m` |
:::

Next: [ControlSystem.m](@code/control-system) — the other half of
$f(t,x)$.
