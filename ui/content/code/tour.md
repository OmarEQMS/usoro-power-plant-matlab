---
description: The repository at a glance — where the model lives, how a simulation runs end to end, and one annotated derivative evaluation.
---

# Repository tour

All model code lives in the MATLAB package `src/+model` — thirteen classes
that together turn a 47-element state vector into its time derivative —
plus test entry points in `src/+test` and an interactive dashboard. This
page shows the shape of the whole thing; the rest of the section takes the
files one at a time.

## The one call that is the entire model

Everything the plant does happens inside a single function evaluation:
given time $t$ and state $x$, produce $\dot x = f(t, x)$. One RK4
integration step calls it four times. In MATLAB:

```matlab
par  = model.Parameters();
sim  = model.Simulator(model.PowerPlant(par), ...
                       model.ControlSystem(par), ...
                       model.LoadProfile.test1());
res  = sim.run(model.InitialConditions.at100(), 700);
```

Inside `sim.run`, each derivative evaluation flows through the classes in
a fixed order:

```matlab
function [xdot, sig, u] = derivative(obj, t, x)
    s = model.StateVector.unpack(x);          % named states
    u = obj.control.actuatorCommands(s);      % demands -> valve areas, flows
    g = struct('nelec', obj.grid.frequency(t), 'velec', obj.grid.voltage(t));
    [xdot, sig] = obj.plant.evaluate(s, u, g); % physics: states 1-22, 47
    xdot = xdot + obj.control.derivatives(s, u, sig, obj.profile.demand(t));
end
```

Two things are worth noticing already:

- **`sig` is the signal bus.** The plant accumulates every intermediate
  quantity — flows, pressures, temperatures, heat rates — in one struct
  under its thesis name. The control system reads its measurements from
  it, and the logger picks its columns from it.
- **Physics and control never overlap.** `PowerPlant` fills derivative
  entries 1–22 and 47; `ControlSystem` fills 23–46. The sum is the full
  $\dot x$.

::: code-map The cast of classes
| Class | Role |
|---|---|
| `Parameters` | all 306 constants, generated from the thesis data deck |
| `StateVector` | index map and pack/unpack for the 47 states |
| `SteamTables` | 16 water/steam property fits |
| `Hydraulics` | closed-form flow-network solvers |
| `Turbomachinery` | turbine extractions, motors, feed pump turbine |
| `HeatTransfer` | furnace radiation and convective exchangers |
| `VesselDynamics` | drum and deaerator saturated-vessel balances |
| `PowerPlant` | the physical plant: algebra + physical derivatives |
| `ControlSystem` | 11 control loops + actuator transducers |
| `LoadProfile` / `GridProfile` | scenario inputs $ldc(t)$, grid $f(t)$, $V(t)$ |
| `Simulator` | RK4 stepping, logging, scenario assembly |
:::

## Where things are

```
src/
├─ +model/          the model package (classes above)
├─ +test/           test.run1 .. test.run7  — the thesis' seven tests
├─ tools/           trim_operating_points.m — steady-state generator
├─ PlantApp.m       interactive dashboard (programmatic uifigure)
└─ run_ui.m         dashboard launcher
```

Continue with [naming and conventions](@code/conventions) — the thesis'
FORTRAN symbol names survive everywhere in this code base, and reading
them fluently is half the battle.
