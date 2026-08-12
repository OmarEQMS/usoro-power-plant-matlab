---
description: Two methods carry all the boiler's heat — the furnace radiant balance and the reusable convective-bank solve, chained four times in flue-gas order.
sourceFile: src/+model/HeatTransfer.m
---

# HeatTransfer.m

The smallest of the static libraries: two methods. One solves the
[furnace's radiant balance](@plant/furnace); the other is the
*reusable* convective-bank model that `PowerPlant` instantiates four
times — primary superheater, secondary superheater, reheater,
economizer — in [flue-gas order](@basics/heat-transfer).

::: why
Five heat rates (`qwwgm`, `qps`, `qss`, `qrh`, `qec`) drive every
boiler-side energy state, and all five are computed here. This file is
also — together with `Hydraulics.airGas` — the open fuel/air-offset
investigation's territory: a slip in one absorption equation would
explain the model's uniform extra firing.
:::

## The furnace

```matlab
[tfn1, twwge, twwgo, qwwgm, qpsr, swwgo] = furnace( ...
    twwm, wwwg, war, sar, tapao, wfl, sfl, tfl, khfl, efl, ...
    wgr, sgr, tgr, uwwgm, ywgr, tpse, kupsr)     % thesis FNXFER
```

Seventeen inputs because the fire has many ingredients: metal
temperature (the radiation sink), the three gas streams with their
specific heats and temperatures (`war/sar/tapao`, `wfl/sfl/tfl`,
`wgr/sgr/tgr`), the fuel heat (`khfl`, `efl`), the
[tilt/gun-corrected radiant coefficient](@plant/furnace) `uwwgm`, and
the primary superheater's radiant view (`tpse`, `kupsr`). Out come the
flame's effective temperature, the furnace exit temperature, the big
radiant transfer and the superheater's radiant share. Inside: one
energy balance — release plus inflow enthalpy equals radiation plus
outflow enthalpy — solved for the gas temperatures, with the
[T⁴ law](@basics/heat-transfer) doing the radiating.

## The convective bank

```matlab
[tgo, q, tme, sgo] = convective(wg, ws, kugm, kums, tse, tg1, qr, ywgr)  % thesis HXFER
```

One method, four banks: gas flow and inlet temperature on one side,
steam flow and temperature on the other, the two
[transfer coefficients](@basics/heat-transfer) (`kugm` gas→metal,
`kums` metal→steam) in between, plus any radiant bonus `qr` (nonzero
only for the primary superheater). Returns the heat moved, the gas
*outlet* temperature — which becomes the next bank's `tg1` — and the
implied metal temperature for the
[effective-mass bookkeeping](@basics/mass-energy-balances).

The chaining in `PowerPlant.airGasSide` is the architecture:

```matlab
[tpsgo, qps, ...] = convective(wwwg, wpse, kupsgm, kupsms, tpse, twwgo, qpsr, ywgr);
[tssgo, qss, ...] = convective(wwwg, wsse, kussgm, kussms, tsse, tpsgo, 0, ywgr);
[trhgo, qrh, ...] = convective(wwwg, wrhe, kurhgm, kurhms, trhe, tssgo, 0, ywgr);
[tecgo, qec, ...] = convective(wwwg, wfw,  kuecgm, kuecmw, tece, trhgo, 0, ywgr);
```

Each line's gas-outlet feeds the next line's gas-inlet — *upstream
banks eat first*, in code as in physics. The last outlet, `tecgo`, is
the [stack-side temperature](@plant/economizer-airheater) the
efficiency ledger cares about.

::: caution
The transfer coefficients are constants — design-point values with no
flow or temperature dependence
([the accepted error](@basics/heat-transfer)). When auditing the
absorption split against the thesis, remember both methods are exactly
as good as those constants and the flows feeding them; the equations
themselves have no tuning freedom.
:::

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| the two methods | `furnace`, `convective` | `src/+model/HeatTransfer.m` |
| the four-bank chain | `airGasSide` | `model.PowerPlant` |
| heat consumers | energy states 2, 3, 7, 9, 11, 14 | `model.PowerPlant` |
| coefficients | `ku*` family | `model.Parameters` |
:::

Next: [VesselDynamics.m](@code/vessels) — the saturated-vessel solve
that runs both the drum and the deaerator.
