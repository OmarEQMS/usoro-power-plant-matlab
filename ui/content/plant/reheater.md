---
description: The second superheat — reheating HP exhaust back to 1000 °F, controlled by burner tilt with a spray for emergencies, and why its temperature is the hardest to hold.
---

# Reheater

After the HP (high pressure) turbine has taken its 143 Btu/lbm, the
steam — now "cold reheat" at ≈1317 Btu/lbm and ≈555 psia — comes *back
into the boiler* for a second heating. The reheater returns it to
1000 °F ("hot reheat", 1519 Btu/lbm) before the IP (intermediate
pressure) turbine. The [turbines page](@basics/turbines) explained why
the cycle wants this; here is the hardware and its distinctly awkward
control problem.

::: why
The reheater is the boiler's problem child. It sits far from the fire,
its temperature *falls* at part load (the opposite of the superheaters),
and its main control lever — burner tilt — belongs to the furnace, not
to it. The tilt/recirculation choreography that results is the richest
control story in the plant, and the model reproduces it deadband and
all.
:::

## The hardware

One long tube bank (states 13/14: `rrho`, `hrho`) between the secondary
superheater and the economizer in the gas path, absorbing `qrh` ≈
193,000 Btu/s at full load through 944,000 lbm of metal — the heaviest
bank in the boiler. Flow in is HP exhaust plus an optional spray
(`wrh1 = whpo + wry`); flow out passes the **intercept valve** (`wiv`,
normally wide open — it exists for overspeed protection) into the IP
turbine. The [reheater's balance pair](@basics/mass-energy-balances)
served as this site's worked example of mass/energy balances — the two
lines of `xdot(13)`/`xdot(14)` you have already read.

## Why the reheater runs cold at part load

Reduce load and the furnace fires less; the flame shrinks *and* the gas
reaching the far banks cools disproportionately (the
[T⁴ collapse](@basics/heat-transfer)). Sitting third in the gas path,
the reheater feels it worst: at 77.5% load its unaided outlet would sag
well below set point. Meanwhile its set point stays at 1000 °F down to
about half load (the [schedule's clamp](@basics/control-practices)
holds `ktrh` at 1459.67 °R until `whp` falls to ≈52%). Someone must
push heat *toward* the reheater — without overfiring the whole boiler.

## The levers: tilt first, recirculation behind it, spray for mercy

- **Burner tilt** (fast, strong): tilting the flames up moves radiant
  heat off the waterwalls and hands the convective banks hotter gas —
  the [furnace page's](@plant/furnace) `uxgg` factor. The reheat
  temperature error drives exactly this: the loop's output `cxggd` *is*
  the tilt demand.
- **Gas recirculation** (slow, sustained): when tilt alone runs out —
  specifically, when the tilt demand leaves its ±5° deadband — the
  recirc integrator starts raising `wgr`, adding gas mass that boosts
  every convective bank. As recirculation warms the reheater, the tilt
  relaxes back into its deadband and the integrator freezes wherever it
  stands. Tilt handles transients; recirculation absorbs the steady
  part; and the freeze is why the plant's part-load equilibrium is a
  *band*, not a point.
- **Reheat spray** (last resort, cooling only): up to 50 lbm/s (`wry`)
  injected into cold reheat — and note the wiring: its command is the
  *same signal* as the tilt demand, mapped through an inverted range
  (`cry = kc1ry·cxggd` with `kc1ry = −1`), so spray only opens when the
  tilt demand collapses below 2 V — "reheat far too hot, tilt fully
  down, still too hot." In normal operation it stays shut; spraying
  into reheat is thermodynamically expensive (that water skips the HP
  turbine entirely).

::: metrics The reheater at 100% load
| Quantity | Value |
|---|---|
| Flow | ≈1004 lbm/s (HP exhaust) |
| In / out conditions | ≈555 psia, 1317 Btu/lbm → 1000 °F, 1519 Btu/lbm |
| Absorption `qrh` | ≈193,000 Btu/s |
| Fill volume / metal mass | 6000 ft³ / 944,000 lbm |
| Set point | 1000 °F, clamped; scheduled below ≈52% flow |
| Spray `wry` range | 0–50 lbm/s (normally 0) |
:::

::: caution
This model runs more gas recirculation than the thesis reports at the
same part-load points (≈360 vs 337 lbm/s at 77.5%). The recirc level
is only loosely pinned by the plant: its integrator acts *only* while
the burner tilt sits outside the ±5° deadband, so the steady value is
path-dependent within a band (≈355–385 lbm/s at 77.5%) — and the
thesis' 337 lies outside this model's band (re-seeded there, the plant
pumps it back to ≈356). The control logic itself matches the thesis
deck constant for constant; the exact recirc level is honest to this
model's heat balance.
:::

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| reheater states | `xdot(13)`, `xdot(14)` | `model.PowerPlant` |
| intercept valve | `wiv = kip·aiv·√(rrho·prho)` | `model.PowerPlant` |
| tilt demand / deadband | `cxggd` (state 42), `knp087` gate | `model.ControlSystem` |
| recirc integrator | `c2gr` (state 27), `cgrd` (state 38) | `model.ControlSystem` |
| reheat spray | `wry` from `cry = kc1ry·cxggd` | `ControlSystem.actuatorCommands` |
:::

Next: [Economizer and air heater](@plant/economizer-airheater) — the
last two stops before the stack, where the boiler squeezes its exhaust.
