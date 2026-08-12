---
description: Combustion, burner tilt and gun count, gas recirculation entering the fire — and the T⁴ balance that decides how much of 1.5 million Btu/s the waterwalls keep.
---

# Furnace and burners

Everything starts here: a box of flame roughly ten stories tall, lined
with water-filled tubes. Oil and preheated air burn at twenty burner
guns; the flame radiates onto the tube walls; the still-hot gas leaves
the top toward the convective surfaces. Three control handles — fuel
flow, burner tilt, and recirculated gas — make this box the most
*steerable* component in the plant.

::: why
The furnace sets the split of heat between the waterwalls (steam
*production*) and the downstream surfaces (steam *temperature*). Every
temperature-control trick in the plant — tilt, spray, recirculation —
is ultimately an argument with this box about who gets the Btu.
:::

## Combustion

Fuel arrives as oil with heating value 18,200 Btu/lbm (`khfl`); heat
release is simply $w_{fl} \cdot k_{hfl}$ — about $1.46\times10^6$ Btu/s
at the full-load 80 lbm/s. Air arrives preheated to 948 °R
(`tapao`, from the [air heater](@plant/economizer-airheater)) at the
demand ratio `kafr` = 13.65 lbm air per lbm fuel, enforced by the
[cross-limited](@basics/control-practices) air/fuel loops. The burned
mixture plus any recirculated gas forms the total furnace gas flow:

```matlab
sig.wwwg = war + wfl + wgr;   % everything that flows past the waterwalls
```

## The radiant balance

The [heat-transfer page](@basics/heat-transfer) built the law; the
furnace model applies it. `HeatTransfer.furnace` performs an energy
balance on the fire: heat release plus the enthalpy of incoming air and
recirculated gas, minus what radiates to the walls, sets the flame's
**effective gas temperature** `twwge` (≈3600 °R) and the furnace exit
temperature `tfn1` (≈4100 °R at full load) — and out of it comes the
plant's single largest energy transfer:

```matlab
qwwgm = uwwgm*(twwge4 - twwm4);   % ~500,000 Btu/s to the waterwalls
```

A slice of radiation also leaps directly to the first tube bank above
the furnace exit (`qpsr`, the primary superheater's radiant share) —
the one exception to the "radiation heats walls, convection heats
banks" division of labor.

## Handle 1: burner tilt

The burners sit in the furnace corners and can pivot ±30°
(`kxggl/kxggu` = ±0.5236 rad). Tilting the flames **up** moves the
fireball toward the exit: the waterwalls see less of it, the convective
banks inherit hotter gas. The model captures this with a multiplier on
the radiant coefficient:

```matlab
sig.uxgg = P.k1xgg + P.k2xgg*sin(u.xgg)/cos(u.xgg);   % 1 - 0.2865·tan(tilt)
```

Tilt up (+30°): radiant absorption drops ~17%; tilt down: it grows.
That lever belongs to the reheat temperature controller — tilt is how
the plant warms a cold reheater without firing more fuel. See
[the reheat loop](@plant/loops-steam).

## Handle 2: gun count

Not all twenty guns need burn. The model groups them in five elevations
of four (`ng1…ng5`, each 4.0 at full load) and weights each elevation's
contribution to waterwall radiation (`k1ng…k5ng` — lower guns "see" more
wall). The weighted count forms a second multiplier, `ungg`. The
published tests keep all guns lit, but the mechanism is faithful: shut
the top elevation and the fireball drops, exactly like tilting down.

## Handle 3: recirculated gas

Cool (≈1100 °R) gas drawn from the economizer outlet can be blown back
into the furnace floor — up to 500 lbm/s of it. Its effect is the
subtle one: it *dilutes* the fire. Same heat release spread over more
mass means a cooler flame; $T^4$ punishes the radiant transfer for it,
while the extra mass flow *boosts* every convective bank downstream.
Recirculation therefore shifts heat from steam production to steam
temperature — the same direction as tilting up, with a different
mechanism and a slower actuator (its gas temperature follows the fit
`tgr = k1tgr + k2tgr·wfl`). Why the plant needs this at part load — and
how the tilt and recirc loops share the job — is the
[combustion loops page's](@plant/loops-combustion) story.

::: metrics The furnace at 100% load
| Quantity | Value |
|---|---|
| Fuel flow / heat release | 80 lbm/s / 1.46×10⁶ Btu/s |
| Air flow | ≈1230 lbm/s |
| Gas recirculation | ≈184 lbm/s |
| Furnace exit temperature `tfn1` | ≈4140 °R |
| Waterwall radiant absorption | ≈500,000 Btu/s (34% of fuel heat) |
| Furnace pressure | 14.7 psia (held by ID fans) |
:::

::: caution
The furnace model is algebraic — no stored state of its own. Flame
dynamics (seconds) are far faster than anything the 0.1 s step needs to
resolve, so the fire is always in instantaneous balance with its
inputs. The furnace's *memory* lives next door, in the waterwall metal
temperature (state 7).
:::

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| tilt/gun multipliers | `sig.uxgg`, `sig.ungg`, `sig.uwwgm` | `PowerPlant.airGasSide` |
| furnace balance | `HeatTransfer.furnace(...)` → `tfn1, twwge, qwwgm, qpsr` | `model.HeatTransfer` |
| recirc gas temperature | `sig.tgr = P.k1tgr + P.k2tgr*u.wfl` | `PowerPlant.airGasSide` |
| fuel/air/recirc demands | `cfld`, `card`, `cgrd` (states 36, 35, 38) | `model.ControlSystem` |
:::

Next: [Waterwalls, drum and circulation](@plant/waterwalls-drum) — where
those 500,000 Btu/s boil water.
