---
description: Two superheater stages with a desuperheating spray between them — how saturated drum steam becomes 1000 °F main steam, and how that temperature is held.
---

# Superheaters and spray

Steam leaves the [drum](@plant/waterwalls-drum) saturated — as hot as
boiling at drum pressure allows, ≈680 °F, and carrying droplets of
moisture. The turbines want it *superheated*: 1000 °F, bone dry. Two
tube banks hanging in the hottest gas do that work, and a water spray
between them provides the fine temperature control. Four of the model's
states live here — a density/enthalpy pair per stage.

::: why
Main steam temperature is a hard ceiling, not a preference: 1000 °F sits
just under what 1970s superheater alloys tolerate continuously. Too hot
shortens tube and turbine life; too cold costs efficiency and pushes the
LP (low pressure) exhaust wetter. Holding 1000 °F across load changes —
with combustion, flow and fouling all moving — is one of boiler
control's defining problems.
:::

## The two-stage path

Drum steam flows first through the **primary superheater** (states 8/9:
`rpso`, `hpso`), the bank sitting closest to the furnace exit — it takes
the hottest gas, absorbs `qps` ≈ 174,000 Btu/s at full load, and is the
one bank that also receives direct furnace radiation (`qpsr`, from the
[furnace page](@plant/furnace)). Then through the **secondary
superheater** (states 10/11: `rsso`, `hsso`), absorbing `qss` ≈ 209,000
Btu/s and delivering main steam to the throttle at 2415 psia / 1000 °F.
Each stage is the standard
[mass + energy balance pair](@basics/mass-energy-balances) with its
[effective metal mass](@basics/heat-transfer) — 350,000 lbm of steel in
the primary, 800,000 in the secondary.

## The spray: control by calculated sabotage

Between the stages sits the **desuperheater**: a nozzle injecting up to
100 lbm/s of cold feedwater (`wsy`) straight into the steam. Evaporating
spray water absorbs enthalpy immediately — it is deliberate
de-superheating, spending a little thermodynamic efficiency to buy exact
temperature control. The mixed state after injection comes from a
dedicated fit (`superheatSprayMix`, thesis SYSTAT), and the
[superheat loop](@plant/loops-steam) commands the spray from the main
steam temperature error against its
[scheduled set point](@basics/control-practices) `ktss`.

Why inject *between* the stages rather than at the outlet? Two reasons
worth remembering: the secondary superheater downstream re-mixes and
re-measures the steam, so control acts through real thermal dynamics
instead of spraying droplets straight at the turbine; and the injection
point's lower temperature keeps the spray water from flashing too
violently. The cost: control acts through the secondary's thermal lag —
minutes, not seconds — which is why the loop carries rate compensation
in its design.

## Why temperature *rises* when load falls

A subtlety that shapes the whole control problem: at part load, steam
flow drops faster than gas heat does — each pound of steam lingers
longer in hot gas — so superheat temperature tends to *rise* as load
falls (convective superheaters "run hot at low load"). The spray must
open on load *decreases*. The reheater next door has the opposite
problem, and the contrast between the two pages is the heart of boiler
temperature control.

::: metrics Superheaters at 100% load
| Quantity | Value |
|---|---|
| Main steam out | 1109 lbm/s, 2415 psia, 1000 °F (h = 1460 Btu/lbm) |
| Primary absorption `qps` (+ radiant `qpsr`) | ≈174,000 Btu/s |
| Secondary absorption `qss` | ≈209,000 Btu/s |
| Spray `wsy` range | 0–100 lbm/s |
| Fill volumes (primary / secondary) | 2000 / 3000 ft³ |
| Metal masses | 350,000 / 800,000 lbm |
:::

::: caution
The model lumps each stage to a single node, so steam temperature
*inside* a bank is one number — real superheaters have profiles along
the tubes, and their hottest metal (the design constraint) is hotter
than the lumped value. The model's 1000 °F is the mixed outlet, which is
what the control system sees and controls.
:::

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| stage states | `xdot(8..11)` — mass/energy pairs | `model.PowerPlant` |
| spray mix state | `superheatSprayMix(h, p)` (thesis SYSTAT) | `model.SteamTables` |
| spray flow | `wsy` from `csyd` via transducer | `ControlSystem.actuatorCommands` |
| absorptions | `qps`, `qpsr`, `qss` | `model.HeatTransfer` |
| set-point schedule | `ktss = k1tss + k2tss·whp`, clamped | `ControlSystem.derivatives` |
:::

Next: the [reheater](@plant/reheater) — same job, second pass, harder
control problem.
