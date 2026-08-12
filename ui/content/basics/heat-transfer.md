---
description: Radiation, convection and metal thermal mass — the three mechanisms that move 1.5 million Btu/s from flame to steam, at exactly the depth the model uses.
---

# Heat transfer

The furnace releases about $1.5\times10^6$ Btu/s at full load. Every one
of those Btu that reaches the steam does so by exactly two mechanisms —
**radiation** from the flame, **convection** from the flue gas — usually
with a stop in between: the steel of the heat-exchanger walls. This page
covers all three at the model's working depth.

::: why
The five heat absorptions `qwwgm`, `qps`, `qss`, `qrh`, `qec` are the $Q$
terms of every boiler-side [energy balance](@basics/mass-energy-balances),
and their split — how much heat lands in *which* surface — is what the
burner tilt and gas recirculation controls manipulate. This page is the
physics those controls play against.
:::

## Radiation: the $T^4$ law

A flame at ≈3600 °R radiates. Radiant exchange between a hot gas volume
and the wall enclosing it grows as the *fourth power* of absolute
temperature:

::: equation Radiant absorption (waterwalls)
$$q_{ww} \;=\; U_r\,\big(T_{\mathrm{gas}}^4 - T_{\mathrm{metal}}^4\big)$$
:::

and in the model, verbatim (`HeatTransfer.furnace`):

```matlab
qwwgm = uwwgm*(twwge4 - twwm4);
```

The fourth power has two consequences worth internalizing. First, the
flame side dominates: at 3600 °R vs the wall's ≈1200 °R, the gas term is
~80× the metal term — radiation is effectively a one-way firehose aimed
at the waterwalls. Second, radiant absorption *collapses* at part load:
lower firing cools the flame, and $T^4$ amplifies the drop — which is
why partial-load operation needs tricks (tilt, recirculation) to keep
the downstream surfaces fed. The coefficient itself is modulated by the
burner tilt and burner count — that is the `uwwgm = kuwwgm·uxgg·ungg`
chain, covered with the [furnace](@plant/furnace).

## Convection: effectiveness along a chain

Past the furnace exit, the flue gas sweeps in sequence over the tube
banks — primary superheater, secondary superheater, reheater, economizer
— giving up heat to each. For one bank, the model uses the standard
two-resistance picture: gas convects to the tube metal (coefficient
$U_{gm}$), metal convects to the steam inside (coefficient $U_{ms}$):

```matlab
[sig.tpsgo, sig.qps, sig.tpsme, sig.spsgo] = model.HeatTransfer.convective( ...
    sig.wwwg, sig.wpse, P.kupsgm, P.kupsms, sig.tpse, sig.twwgo, sig.qpsr, P.ywgr);
```

Each call takes the gas flow and inlet temperature, the steam flow and
temperature, the two coefficients — and returns the heat transferred,
the gas *outlet* temperature, and the metal temperature. The outlet of
one bank is the inlet of the next: the four calls chain in flue-gas
order, and whatever leaves the last (the economizer's `tecgo`, ≈1100 °R)
goes to the air heater and stack. That ordering is the entire
architecture of the boiler's convective side: **upstream banks eat
first**, and any change in gas flow or temperature propagates down the
chain.

## Metal in the middle: thermal mass

Between gas and steam sits steel — a *lot* of steel (the reheater alone
carries 944,000 lbm of it, the secondary superheater 800,000). Steel
stores heat: raising 800,000 lbm of metal (specific heat ≈0.11
Btu/lbm·°R) by one degree swallows 88,000 Btu that never reach the
steam. This storage is why boilers respond in minutes, not seconds.

The model carries the metal two ways. The waterwall metal temperature is
a full state — heat in by radiation, out by boiling:

```matlab
xdot(7) = (sig.qwwgm - sig.qwwmw)/(sig.mwwme*P.kswwm);
```

— while each convective bank's metal is lumped into its exchanger's
[effective mass](@basics/mass-energy-balances), storing heat without its
own state. One more empirical law completes the loop: boiling water
removes heat from the waterwall metal at a rate the model fits as a
*cube* of the temperature difference to the drum's saturation
temperature — nucleate boiling is ferociously effective, so the metal
never runs far above the water temperature:

```matlab
sig.qwwmw = P.kuwwmw*(s.twwm - sig.tdrs)^3;
```

::: caution
The heat-transfer coefficients (`kupsgm`, `kussms`, …) are design-point
fits, held constant. Real coefficients drift with flow and temperature;
the model accepts that error to stay algebraic. When investigating
steady-state offsets between model and thesis, these constants — and the
absorption split they set — are prime suspects, precisely because
nothing regulates them.
:::

::: metrics The absorption ledger at 100% load (Btu/s)
| Surface | Heat absorbed |
|---|---|
| Waterwalls (radiant) | ≈500,000 |
| Primary superheater | ≈174,000 |
| Secondary superheater | ≈209,000 |
| Reheater | ≈172,000 |
| Economizer | ≈151,000 |
| Fuel heat input | ≈1,459,000 |
:::

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| furnace radiation | `furnace(...)` → `qwwgm`, `tfn1`, `twwgo` | `model.HeatTransfer` |
| convective banks | `convective(wg, ws, kugm, kums, …)` ×4 | `model.HeatTransfer` |
| waterwall metal state | `xdot(7)`, state `twwm` | `model.PowerPlant` |
| boiling-side removal | `qwwmw = kuwwmw*(twwm - tdrs)^3` | `model.PowerPlant` |
:::

Next: [Rotating machinery](@basics/rotating-machinery) — torque balances,
induction motors, and why grid voltage reaches into every corner of the
plant.
