---
description: The last two heat recoveries before the stack — the economizer warming feedwater and the air heater warming combustion air — and the fixed-temperature simplification the model makes.
---

# Economizer and air heater

Flue gas leaving the [reheater](@plant/reheater) still carries around
1600 °R of temperature — pure loss if it goes up the stack. Two final
exchangers mine it: the **economizer** hands gas heat to the incoming
feedwater, and the **air heater** hands what remains to the incoming
combustion air. Between them they are the difference between a boiler
that wastes a fifth of its fuel and one that wastes a tenth.

::: why
Boiler efficiency is decided here, at the cold end. Every degree of gas
temperature entering the stack is fuel bought and thrown away: of the
≈88% of fuel heat the boiler absorbs at rated load, the last two
stages of recovery — economizer and air heater — are what keep the
stack loss down to the remaining ≈12%. Understanding the cold end is
understanding where the efficiency ledger closes.
:::

## The economizer

The last tube bank in the gas path (state 3: `heco`), taking feedwater
from the HP heaters at 478 Btu/lbm and delivering it to the drum at
≈635 — still ≈50 Btu/lbm short of boiling, a deliberate **approach
margin** so the economizer never generates steam inside its own tubes
(steaming economizers pound and corrode). Its absorption `qec` ≈
165,000 Btu/s at full load comes through 721,000 lbm of metal.

The name is literal Victorian bookkeeping: the device *economizes* —
heat recovered here is fuel not burned. And note the elegant
double-counting-avoidance in the plant's design: feedwater heating by
*extraction steam* (the [turbine page's](@basics/turbines) trade) stops
at 478 Btu/lbm precisely so the economizer has gas heat left to absorb;
the two heating strategies split the feedwater's temperature climb
between them.

One modeling nuance: unlike the steam banks, the economizer carries
only an *energy* state, no density state — compressed liquid water is
effectively incompressible, so its mass storage never changes
meaningfully. One balance instead of two.

## The air heater

After the economizer, the gas (≈1105 °R at full load) makes its last
transfer: a rotating-matrix exchanger warms the FD (forced draft) fans'
air from ≈598 °R up to 948 °R before the windbox. That is ≈100,000
Btu/s re-entering the furnace with the air — heat that cycles around
the combustion loop instead of escaping. Only then does the gas pass
the ID (induced draft) fans and leave up the stack.

Here the model makes its boldest simplification: **the air heater has
no dynamics and no balance — its temperatures are constants.**

```matlab
sig.tahao = P.ktat + P.ktahad;        % air heater air inlet-side: 598 R
sig.tapao = sig.tahao + P.ktapad;     % preheated air out: 948 R, always
```

At every load, in every transient, combustion air arrives at exactly
948 °R. The thesis judged the air heater's slow, mild variations
second-order for emergency-transient purposes — a defensible trade that
keeps two states and one exchanger model out of the problem.

::: caution
That simplification has an accounting consequence: since the air-side
pickup is fixed while the gas-side delivery varies with load, the air
heater does not close an exact energy balance — the stack loss the
model implies is not precisely the fuel heat minus the absorptions.
The model accepts this bookkeeping slack by design; it is one reason
audits of the boiler's energy ledger work from the absorbed fractions
(the [heat-transfer](@code/heat-transfer) side) rather than from a
stack-loss residual.
:::

::: metrics The cold end at 100% load
| Quantity | Value |
|---|---|
| Economizer absorption `qec` | ≈165,000 Btu/s |
| Feedwater through it | 478 → ≈635 Btu/lbm (≈50 short of boiling) |
| Gas to the air heater `tecgo` | ≈1105 °R |
| Air preheat (fixed) | 598 → 948 °R |
| Economizer metal / volume | 721,000 lbm / 2100 ft³ |
:::

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| economizer state | `xdot(3)` — energy balance on `heco` | `model.PowerPlant` |
| absorption | `qec` — last `convective(...)` call in the chain | `PowerPlant.airGasSide` |
| fixed air-heater temps | `tahao`, `tapao` from `ktat/ktahad/ktapad` | `PowerPlant.airGasSide` |
| gas exit temperature | `sig.tecgo` | `model.HeatTransfer` |
:::

Next: [Fans and the air/gas path](@plant/air-gas-path) — the machinery
that moves 1400 lbm/s of air and gas through everything described so
far.
