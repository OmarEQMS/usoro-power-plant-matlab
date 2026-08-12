---
description: The boiling loop — downcomers, recirculation pumps, waterwall tubes and the steam drum — and the saturated-vessel mathematics that make drum level the trickiest signal in the plant.
---

# Waterwalls, drum and circulation

The drum is the boiler's heart: a thick-walled horizontal cylinder,
half water, half steam, sitting at 2778 psia. Below it runs the
**circulation loop**: water descends through downcomers, recirculation
pumps push it through the furnace-wall tubes (the waterwalls), the
[furnace's radiation](@plant/furnace) boils part of it, and the
steam–water mixture returns to the drum, where steam separates and
leaves for the superheaters. Four states live here — drum water volume,
drum steam density, waterwall metal temperature, and pump speed — and
two of them form the model's most mathematically interesting vessel.

::: why
The drum is where steam *production* is set and where the feedwater
loop closes. It is also the home of the plant's most counterintuitive
measurement — drum level, which moves the *wrong way* first during
transients. Operators have drowned turbines trusting that signal
naively; the model reproduces exactly why.
:::

## The circulation loop

Boiling inside a vertical tube must be *fed*: circulation keeps each
pound of waterwall water moving so that only a fraction of it boils per
pass. The loop's flow `wrw` comes from the
[recirculation pump network solve](@basics/pumps-fans) — pump curve
against downcomer and waterwall friction. The riser flow returns to the
drum as a mixture whose quality the model computes from the waterwall
energy balance:

```matlab
sig.qyww = (sig.qwwmw + sig.wrw*(sig.hrpo - sig.hdrw))/(sig.wrw*sig.hdrd);
```

— absorbed boiling heat `qwwmw` (the [cube law](@basics/heat-transfer))
turned into vapor fraction. Meanwhile the metal state mediates: furnace
radiation charges the steel, boiling discharges it:

```matlab
xdot(7) = (sig.qwwgm - sig.qwwmw)/(sig.mwwme*P.kswwm);
```

## A saturated vessel: two states, everything coupled

Inside the drum, liquid and vapor coexist *at saturation* — the
[tightened two-property rule](@basics/thermo-properties) applies, and
one number (steam density `rdrs`) fixes both phases' properties via the
`drumSaturation` fits. The model tracks two stored quantities:

- `vdrw` (state 4) — water volume, ft³;
- `rdrs` (state 5) — steam density, lbm/ft³.

But here is the subtlety: mass and energy conservation constrain
*totals*, while boiling and condensation move mass **between the
phases inside the vessel**. Add feedwater and some drum steam
condenses; drop the pressure and some drum water flashes. The two state
derivatives must be solved *jointly* from the vessel's net mass and
energy imbalances:

```matlab
sig.z206 = wfw - wrw + wwwo - wdrs - wdrbd;          % net mass, lbm/s
sig.z209 = wwwo*hwwo - (wrw - wfw)*hdrw - ...        % net energy, Btu/s
[sig.f1dr, sig.f2dr] = model.VesselDynamics.saturatedVessel( ...
    P.kvdr, s.vdrw, s.rdrs, ..., sig.z206, sig.z209);
xdot(4) = sig.f1dr;      % d(vdrw)/dt
xdot(5) = sig.f2dr;      % d(rdrs)/dt
```

`saturatedVessel` inverts a 2×2 linear system built from the saturation
fits' slopes: *given* this net mass and energy inflow, how must volume
and density move so that both phases stay saturated? The same function,
with different fit constants, runs the deaerator (states 19/20) — one
piece of mathematics, two vessels.

## Shrink and swell: the level that lies

Drum level (`xdrw`, a fit on water volume) is the feedwater
controller's key measurement — and it is famously deceptive:

::: definition Shrink and swell
Steam demand rises → drum pressure dips → bubbles throughout the
circulation loop *expand* and drum water flashes → the level **swells
upward**, exactly when more feedwater (which will read as level
falling... eventually) is needed. Load drops produce the mirror-image
*shrink*. The level's first move is opposite to the mass trend it
supposedly indicates.
:::

This is why the [feedwater loop](@plant/loops-steam) is *three-element*
— it trusts level only in combination with steam-flow and
feedwater-flow measurements that see through the transient. The model
reproduces shrink/swell mechanistically (flashing is exactly what the
joint vessel solve computes), and you can watch it in Test 1's drum
level trace: a brief rise as load falls, then the true trend.

## Blowdown

A small continuous stream (`wdrbd`) leaves the drum bottom, carrying
away dissolved solids that would otherwise concentrate as pure steam
departs. Thermodynamically it is a leak of hot, high-pressure water —
one of the balance's standing loss terms.

::: metrics The drum at 100% load
| Quantity | Value |
|---|---|
| Pressure | ≈2778 psia (sat. ≈680 °F) |
| Total volume `kvdr` | 1958.7 ft³ |
| Water volume `vdrw` | 1170.5 ft³ |
| Steam density `rdrs` | 9.45 lbm/ft³ |
| Level range (transducer) | ±15 in |
| Steam out `wdrs` | ≈1110 lbm/s |
:::

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| joint vessel solve | `saturatedVessel(...)` → `f1dr, f2dr` | `model.VesselDynamics` |
| drum imbalances | `sig.z206`, `sig.z209` | `PowerPlant.vesselBalances` |
| saturation properties | `drumSaturation(rs)` | `model.SteamTables` |
| level fit | `sig.xdrw = k1xdrw + k2xdrw·vdrw + k3xdrw·vdrw²` | `PowerPlant.machines` |
| circulation loop | `recirculation(...)`, states 6, 7 | `model.Hydraulics`, `PowerPlant` |
:::

Next: [Superheaters and spray](@plant/superheaters) — drying the drum's
steam and pushing it to 1000 °F.
