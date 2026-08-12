---
description: From hotwell to drum — condensate pumps, LP heaters, the deaerator, the steam-driven feed pump and HP heaters, lifting water 2800 psia and 430 Btu/lbm back to the boiler.
---

# The feedwater train

The [condenser](@plant/condenser) left us with ≈100 °F water at
near-vacuum; the [drum](@plant/waterwalls-drum) needs it back at
2778 psia and 478 Btu/lbm, 1100+ lbm/s of it, continuously. The train
that does this — two pump stations, five heater stations, one
deaerating tank — carries six of the model's states and two of its
eleven control loops.

::: why
The feedwater train is where the [extraction strategy](@basics/turbines)
pays out: every heater is turbine steam buying boiler efficiency. It is
also the plant's most safety-critical water path — lose feedwater and
the drum empties in about a minute at full steaming rate.
:::

## Station by station

**Condensate pumps** (state 17, `ncp`, motor-driven) lift hotwell water
to ≈150 psia — enough to push through the LP (low pressure) heater
string and the deaerator's admission valve, via the `condensate`
network solve.

**LP heaters** (state 18, `hlho`): two shells warmed by LP-turbine
extraction steam, raising the condensate to 199 Btu/lbm. Their energy
balance is the standard pattern:

```matlab
xdot(18) = (sig.wcw*(sig.hcpo - s.hlho) + sig.qlh + P.kqgc)/sig.mlhe;
```

(`kqgc` is a constant gland/coolers heat credit — small equipment heat
that always lands in this stream.)

**The deaerator** (states 19/20, `vdew`, `rdes`) is the train's
centerpiece and its second
[saturated vessel](@plant/waterwalls-drum) — same joint mass/energy
mathematics as the drum, different fits, lower pressure (≈57 psia at
full load):

::: definition Deaeration
Dissolved oxygen in boiler water corrodes steel at high temperature.
The deaerator strips it by **direct contact**: condensate sprays into a
steam-filled vessel, heats to saturation — where gas solubility drops
to nearly zero — and the liberated air vents. The heating steam is IP
extraction, so deaeration doubles as a (contact) feedwater heating
stage.
:::

Being a free surface mid-train, the deaerator is also the train's
buffer tank: its **level** (a fit on `vdew`) absorbs the mismatch
between condensate flow (controlled at the deaerator inlet valve `adv`)
and feed pump draw — the deaerator-level loop is one of the model's
eleven.

**Booster + feed pump** (state 1, `nfp`): the
[steam-driven](@basics/rotating-machinery) main lift, 150 → ≈2900 psia,
through the pump-curve network of the
[pumps page](@basics/pumps-fans). Its speed is commanded indirectly:
the FP-turbine loop holds the *feedwater-valve differential pressure*
(`pfvd`) at 30 psi, so the pump always develops just enough head for
the valve to meter comfortably — a pressure-follower scheme that saves
throttling loss.

**Feedwater valve** (`afv`) is where the
[three-element feedwater control](@plant/loops-steam) actually acts,
metering flow against the drum's demands.

**HP heaters** (state 2, `hhho`): the final two shells, warmed by HP
exhaust and cross-over extractions, delivering 478 Btu/lbm water to the
[economizer](@plant/economizer-airheater). Their steam side drains
back toward the deaerator, closing the extraction ledger.

## Dynamics worth knowing

The train's fast end is electrical (condensate pump, seconds), its slow
end thermal (heater enthalpies, minutes) — and its stability hinges on
two level controls (drum, deaerator) whose measured variables both
[lie during transients](@plant/waterwalls-drum) (the deaerator flashes
and swells exactly like the drum; same vessel mathematics, same
deception). Test 5's voltage dip brushes the train (motors slow
slightly); the thesis notes a 40% dip variant would drop condensate
flow below demand and walk the deaerator level toward a trip — the
train's designed-in fragility.

::: metrics The train at 100% load
| Quantity | Value |
|---|---|
| Feedwater to drum `wfw` | ≈1110 lbm/s |
| Enthalpy ladder | 68 (hotwell) → 199 (`hlho`) → deaerator sat → 478 (`hhho`) Btu/lbm |
| Deaerator pressure | ≈57 psia |
| Feed pump speed / duty | 542 rad/s, ≈150 → 2900 psia |
| FW-valve ΔP set point | 30 psi (`kpfvd`) |
:::

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| condensate network | `condensate(pcn, …, ncp, adv, kncp)` | `model.Hydraulics` |
| LP/HP heater states | `xdot(18)`, `xdot(2)` | `model.PowerPlant` |
| deaerator vessel | `xdot(19)`, `xdot(20)` via `saturatedVessel` | `model.VesselDynamics` |
| feed pump network | `feedwater(…, afv, nfp)` | `model.Hydraulics` |
| FP-turbine ΔP loop | `pfvd` vs `kpfvd`, states 28/39 | `model.ControlSystem` |
:::

Next: [Generator and grid](@plant/generator) — the shaft's far end,
where megawatts leave the property.
