---
description: The complete annotated 47-state reference — indices, names, units, owning component — and the pack/unpack machinery around it.
sourceFile: src/+model/StateVector.m
---

# StateVector.m and the 47 states

One class owns the meaning of "state 16": `StateVector` holds the index
constants, the name list, and the `unpack` helper that turns a bare
47-element column into named fields. This page is the full reference
table — the one to keep open while reading any other file.

::: why
Everything in the model is positional: `x(16)` *is* the turbine speed
because the thesis' data deck says so, and every integrator, logger and
initial-conditions file agrees on the ordering. `StateVector` is the
single place that ordering is written down in code — and this page is
its documentation.
:::

## The machinery

```matlab
s = model.StateVector.unpack(x);   % s.ntr, s.hsso, ... named access
model.StateVector.NTR              % 16 — index constants for x(...)
model.StateVector.names()          % {'nfp','hhho',...} for labeling
```

`unpack` is called once per derivative evaluation; after it, model code
reads `s.rdrs` instead of `x(5)` — self-documenting at zero cost.

## Physical states (1–22, 47)

| # | Name | Unit | Lives in |
|---|---|---|---|
| 1 | `nfp` | rad/s | [feed pump turbine](@plant/feedwater-train) |
| 2 | `hhho` | Btu/lbm | [HP feedwater heaters](@plant/feedwater-train) |
| 3 | `heco` | Btu/lbm | [economizer](@plant/economizer-airheater) |
| 4 | `vdrw` | ft³ | [drum](@plant/waterwalls-drum) (water volume) |
| 5 | `rdrs` | lbm/ft³ | [drum](@plant/waterwalls-drum) (steam density) |
| 6 | `nrp` | rad/s | [recirculation pump](@plant/waterwalls-drum) |
| 7 | `twwm` | °R | [waterwall metal](@basics/heat-transfer) |
| 8 | `rpso` | lbm/ft³ | [primary superheater](@plant/superheaters) |
| 9 | `hpso` | Btu/lbm | [primary superheater](@plant/superheaters) |
| 10 | `rsso` | lbm/ft³ | [secondary superheater](@plant/superheaters) |
| 11 | `hsso` | Btu/lbm | [secondary superheater](@plant/superheaters) |
| 12 | `rsco` | lbm/ft³ | [steam chest](@plant/turbine-train) |
| 13 | `rrho` | lbm/ft³ | [reheater](@plant/reheater) |
| 14 | `hrho` | Btu/lbm | [reheater](@plant/reheater) |
| 15 | `rcro` | lbm/ft³ | [cross-over pipe](@plant/turbine-train) |
| 16 | `ntr` | rad/s | [turbine–generator](@plant/generator) |
| 17 | `ncp` | rad/s | [condensate pump](@plant/feedwater-train) |
| 18 | `hlho` | Btu/lbm | [LP feedwater heaters](@plant/feedwater-train) |
| 19 | `vdew` | ft³ | [deaerator](@plant/feedwater-train) (water volume) |
| 20 | `rdes` | lbm/ft³ | [deaerator](@plant/feedwater-train) (steam density) |
| 21 | `nfd` | rad/s | [FD fans](@plant/air-gas-path) |
| 22 | `nid` | rad/s | [ID fans](@plant/air-gas-path) |
| 47 | `delta` | rad | [generator power angle](@plant/generator) |

Note the patterns: density/enthalpy *pairs* for every steam volume
(the [mass/energy balances](@basics/mass-energy-balances)), a
volume/density pair for each [saturated
vessel](@plant/waterwalls-drum), six shaft speeds, one metal
temperature, one angle.

## Control states (23–46)

The [two primitive elements](@basics/control-basics), loop by loop
([the map](@plant/control-room)):

| # | Name | Role | Loop |
|---|---|---|---|
| 23 | `c3md` | PI integrator | boiler master |
| 24 | `c5ar` | PI integrator | air flow |
| 25 | `c5fl` | PI integrator | fuel flow |
| 26 | `c3fn` | PI integrator | furnace pressure |
| 27 | `c2gr` | deadband integrator | gas recirculation |
| 28 | `c2ft` | PI integrator | FP turbine ΔP |
| 29 | `c3fv` | PI integrator (level) | feedwater |
| 30 | `c7fv` | PI integrator (flow) | feedwater |
| 31 | `c3dv` | PI integrator | deaerator level |
| 32 | `c8dv` | second integrator | deaerator level |
| 33 | `c5rh` | PI integrator | reheat temperature |
| 34 | `c5sy` | PI integrator | superheat temperature |
| 35 | `card` | actuator lag → `avf` | air flow |
| 36 | `cfld` | actuator lag → `wfl` | fuel flow |
| 37 | `cfnd` | actuator lag → `avi` | furnace pressure |
| 38 | `cgrd` | actuator lag → `wgr` | gas recirculation |
| 39 | `cftd` | actuator lag → `wft` | FP turbine |
| 40 | `cfwd` | actuator lag → `afv` | feedwater |
| 41 | `cdwd` | actuator lag → `adv` | deaerator level |
| 42 | `cxggd` | actuator lag → `xgg` | reheat temperature |
| 43 | `csyd` | actuator lag → `wsy` | superheat temperature |
| 44 | `c2tr` | rate-limited integrator | turbine (load reference) |
| 45 | `c4tr` | demand lag | turbine |
| 46 | `cacvd` | actuator lag → `agv` | turbine (governor) |

All 24 live on the [1–5 V scale](@basics/control-practices). The
integrators can wind up past the rails (their *clamped copies* act);
the lags are what the plant physically sees.

::: caution
The ordering is thesis canon — never a free choice. The initial
conditions (thesis p. 288), the trim files, the logger and the
derivative assembly all assume it. Adding a state means touching
`StateVector`, `InitialConditions`, both derivative providers and the
trim files together — by design, the class makes that list explicit.
:::

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| index constants + unpack | `model.StateVector` | `src/+model/StateVector.m` |
| canonical 100% values | `InitialConditions.at100()` | `src/+model/InitialConditions.m` |
| physical derivatives | `xdot(1..22, 47)` | `model.PowerPlant` |
| control derivatives | `xdot(23..46)` | `model.ControlSystem` |
:::

Next: [SteamTables.m](@code/steam-tables) — the sixteen property fits,
cataloged.
