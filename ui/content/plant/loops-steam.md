---
description: Three-element feedwater control, deaerator level, the feed pump's pressure follower, and the two temperature loops — the steam side's five controllers in detail.
---

# Steam-side control loops

The [combustion loops](@plant/loops-combustion) make heat; these five
manage water and temperature. Two are level controls built to survive
[lying measurements](@plant/waterwalls-drum), one is a pressure
follower, and two hold the steam temperatures that protect the turbine.

::: why
The steam side is where control failure means hardware damage in
minutes — a drum run dry, water carried over into the turbine, tubes
over temperature. These loops' designs (three-element, cascade,
scheduled set points) are classic solutions to measurement deception,
and the model carries them wiring-faithful.
:::

## Feedwater: three-element control

The naive loop — level error to feedwater valve — fails on
[shrink and swell](@plant/waterwalls-drum): after a load increase the
level *rises* first, the naive loop would *close* the valve, exactly
wrong. The classic fix uses three measurements (states 29/30/40):

1. **Steam flow** (from the [`p1st` flow meter](@basics/turbines))
   feeds forward: more steam out ⇒ demand more water in, immediately
   and regardless of the lying level;
2. **Feedwater flow** (`wfw`) closes a fast inner loop around the valve
   so the demanded flow is actually delivered;
3. **Drum level** (`xdrw`) trims slowly through its own PI, correcting
   the long-term balance the flows can't see (blowdown, spray draws).

During the swell the flow-balance term dominates and the valve *opens*
while the level still reads high — the design trusts mass balance over
level, short-term. Watch Test 1's feedwater demand trace do precisely
this.

## Deaerator level: the same problem, downstream

The [deaerator](@plant/feedwater-train) swells and flashes like the
drum (same vessel mathematics), and its loop (states 31/32/41) uses
the same medicine in smaller doses: level PI plus condensate
pressure/flow trim terms, acting on the condensate admission valve
`adv`. Its rate feedforward (`fc2dv`) is one of the thesis' stubbed
d/dt terms — [left zero](@basics/control-basics) in the model as in
the original code.

## Feed pump turbine: pressure follower

No level here — this loop (states 28/39) holds the **feedwater valve's
differential pressure** `pfvd` at 30 psi by adjusting the FP (feed
pump) turbine's steam admission `wft`. The effect: the pump
continuously develops *just enough* head for whatever flow the
feedwater valve wants to pass — pump speed follows plant demand
automatically, no flow measurement needed, minimal throttling loss.
Elegant 1970s hardware thinking: one local pressure gauge replaces a
coordination problem.

## Superheat temperature: spray

Main steam temperature `tsso` against its
[scheduled set point](@basics/control-practices) `ktss`, PI (states
34/43), out to the [desuperheater spray](@plant/superheaters) `wsy`.
The loop fights the superheater's minutes-long thermal lag; its
structure includes rate feedforwards from first-stage pressure and
tilt (`fcp1st`, `fcxgg`) — both stubbed to zero, so the model's loop
is a touch slower than the thesis diagrams intend. It shows: watch
`csyd` work hard in the load ramps.

## Reheat temperature: the tilt

Told in full on the [reheater page](@plant/reheater): `trho` against
scheduled `ktrh`, PI (states 33/42), out to burner tilt — with the
recirculation loop as its slow partner and the reheat spray as its
inverted-range emergency valve. Structurally the twin of the superheat
loop; strategically the boiler's most interesting controller, because
its actuator redistributes heat that other loops then feel.

## The steam side in the tests

- **Load ramps (1–4):** both temperature loops work their schedules;
  feedwater rides the swell correctly; nothing saturates below the
  documented capability points.
- **Test 5 (voltage dip):** the train's motors slow — condensate flow
  dips, the deaerator loop compensates; steam side otherwise calm.
- **Tests 6–7:** temperatures are "suitably controlled, but with
  difficulty" (the thesis' own words) — the spray and tilt commands
  spend long stretches at their limits while the combustion side
  starves.

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| 3-element feedwater | `c*fv` block, states 29/30/40 | `ControlSystem.derivatives` |
| deaerator level | `c*dv` block, states 31/32/41 | `ControlSystem.derivatives` |
| FP-turbine ΔP | `c*ft` block, states 28/39; set point `kpfvd` | `ControlSystem.derivatives` |
| superheat spray | `c*sy` block, states 34/43 | `ControlSystem.derivatives` |
| reheat tilt | `c*rh` block, states 33/42 | `ControlSystem.derivatives` |
:::

Next: [Turbine control and the governor](@plant/loops-turbine) — the
loop that spends the boiler's stored energy.
