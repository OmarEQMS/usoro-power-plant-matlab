---
description: Boiler master, air, fuel, furnace pressure and gas recirculation — the five loops that turn a pressure error into fire, in the safe order.
---

# Combustion-side control loops

Five of the [eleven loops](@plant/control-room) manage the fire. One of
them — the boiler master — is not really a loop at all but a *demand
generator* for the other four. This page follows a pressure error
through the whole chain.

::: why
The combustion side is where the plant's capability limits live: every
saturating test ends with these loops' signals pinned at 5 V. Knowing
which signal rails first — and what the cross-limits do about it — is
how you read those trajectories.
:::

## Boiler master: pressure error becomes firing demand

The master measures throttle pressure `psso` against its set point —
scheduled in principle (`kpsso = k1pss + k2pss·ldc`), overridden to a
constant 2415 psia in every published run
([boiler-following](@basics/control-practices)) — and turns the error
into the **common firing demand** through a PI (proportional–integral)
block (integrator: state 23, `c3md`) with a governor-assist term that
anticipates load changes from the turbine side. Its output feeds air
and fuel *jointly* — the master never touches a damper or a valve
itself.

The master's integrator is the plant's designated
[saturation victim](@basics/control-basics): whenever a test makes
2415 psia unreachable (Tests 4, 6, 7), `c3md` pins at its 5 V rail.
It cannot wind up past it — the original FORTRAN clamps the integrator
*state itself* in place (its limiter subroutines act by reference), an
anti-windup the model reproduces by saturating the control states
after every integration step.

## Air and fuel: the cross-limited pair

Both loops chase the master's demand — but
[never symmetrically](@basics/control-practices):

- **Air** (states 24/35): demand = max(master, current fuel) → PI →
  `card` lag → FD (forced draft) vane area `avf`. Air *leads* on the
  way up.
- **Fuel** (states 25/36): demand = min(master, measured air) → PI →
  `cfld` lag → fuel valve → `wfl`. Fuel *follows* air upward, leads
  downward.

The measured-air term is the loops' handshake: fuel consults reality
(`war`, transduced), not intentions. When Test 6's slowed fans cap
actual air, the fuel demand is capped *by that measurement* even while
the master screams for more — the cross-limit converts an air
limitation into a fuel limitation into a megawatt limitation, safely.

## Furnace pressure: the fast trim

The ID (induced draft) vanes (states 26/37) hold `pfn` at 14.7 psia —
and note the instrument design: the pressure transducer's full 1–5 V
range spans just **14 to 15 psia**. A one-psi window on a box the size
of an apartment block: furnace pressure excursions are measured in
hundredths, and this loop works constantly against every air-flow and
firing change the other loops make. (Its structural air feedforward is
zero-gained in the thesis deck — the vanes simply chase the tight
error.)

## Gas recirculation: the odd one

The fifth loop (states 27/38) does not chase the master at all — it
serves the *reheat temperature* strategy, integrating only while the
burner tilt sits outside its ±5° deadband, as the
[reheater page](@plant/reheater) told in full. It lives on the
combustion side because its actuator moves furnace gas; its purpose is
steam-side. When the tilt is content, this loop is frozen scenery.

## Reading a saturation event

Put it together for Test 6 (frequency drop): fans slow → `war` falls →
fuel cross-limit clamps `cfld` → steam production falls → `psso` sags →
master demand climbs → air demand rails at 5 V (it is already asking
for more than the fans can give) → `c3md` saturates at its rail → the
plant settles where *air* says it settles, ≈515 MW. Five loops, one
bottleneck, no drama — which is the design's whole point.

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| master PI + assist | `c*md` block, state 23 | `ControlSystem.derivatives` |
| air loop + cross-limit | `c*ar` block, states 24/35 | `ControlSystem.derivatives` |
| fuel loop + cross-limit | `c*fl` block, states 25/36 | `ControlSystem.derivatives` |
| furnace pressure | `c*fn` block, states 26/37; range `kpfnl/kpfnu` | `ControlSystem.derivatives` |
| recirc deadband loop | `c*gr` block, states 27/38 | `ControlSystem.derivatives` |
:::

Next: [Steam-side loops](@plant/loops-steam) — levels, temperatures
and the feed pump.
