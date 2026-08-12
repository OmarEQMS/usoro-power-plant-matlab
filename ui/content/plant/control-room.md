---
description: The eleven control loops as one system — boiler-following coordination, the master demand, and a map of every loop's measurement, actuator and states.
---

# The control system at a glance

Twenty-four of the model's 47 states belong to controllers. This page
is the map: how eleven loops divide the plant, how the
*boiler-following* philosophy coordinates them, and where each loop's
detailed page lives. It is the hub for the three loop chapters —
[combustion side](@plant/loops-combustion),
[steam side](@plant/loops-steam) and
[turbine](@plant/loops-turbine).

::: why
Each loop alone is textbook [PI-plus-lag](@basics/control-basics). The
plant-ness is in the *interconnections*: one master demand feeding two
cross-limited loops, set points scheduled on a third loop's
measurement, one loop's actuator doubling as another's disturbance.
This map is what keeps `ControlSystem.derivatives` — the model's
longest method — readable.
:::

## The philosophy: turbine leads, boiler follows

Every published test runs **boiler-following**
([mode recap](@basics/control-practices)):

1. Load demand `ldc` goes to the **turbine/governor** loop, which opens
   the governor valves — power responds in seconds, spent from stored
   boiler energy.
2. Throttle pressure `psso` sags below its 2415 psia set point.
3. The **boiler master** turns the pressure error into a common firing
   demand, which the **air** and **fuel** loops (cross-limited) chase
   over the next minutes, restoring pressure.

Fast electrical response bought with stored energy, repaid slowly by
combustion — every load-ramp trace in the thesis (power leading,
pressure dipping and recovering) is this sequence drawn out.

## The eleven loops

| # | Loop | Measures | Acts on | States |
|---|---|---|---|---|
| 1 | Boiler master | `psso` vs 2415 | common demand to 2, 3 | 23 |
| 2 | Air flow | air `war` (cross-limited w/ fuel) | FD vanes `avf` | 24, 35 |
| 3 | Fuel flow | fuel (cross-limited w/ air) | fuel valve → `wfl` | 25, 36 |
| 4 | Furnace pressure | `pfn` vs 14.7 psia | ID vanes `avi` | 26, 37 |
| 5 | Gas recirculation | tilt outside ±5° deadband | recirc `wgr` | 27, 38 |
| 6 | FP turbine | FW-valve ΔP `pfvd` vs 30 psi | FP steam `wft` | 28, 39 |
| 7 | Feedwater (3-element) | `xdrw`, steam flow `p1st`, `wfw` | FW valve `afv` | 29, 30, 40 |
| 8 | Deaerator level | `xdew` + condensate trim | valve `adv` | 31, 32, 41 |
| 9 | Reheat temperature | `trho` vs scheduled `ktrh` | burner tilt `xgg` | 33, 42 |
| 10 | Superheat temperature | `tsso` vs scheduled `ktss` | spray `wsy` | 34, 43 |
| 11 | Turbine / governor | `mwo` vs `ldc`, speed droop | governor `acv` | 44, 45, 46 |

Three structural features tie the table together:

- **One master, two clients.** Loops 2 and 3 do not have independent
  set points — they share the boiler master's demand, filtered through
  the [cross-limits](@basics/control-practices) that keep combustion
  air-rich during every transient.
- **Schedules cross loop boundaries.** Loops 9 and 10 take their set
  points from `whp` — a *turbine* measurement — so the boiler's
  temperature targets follow the load automatically.
- **Actuators are disturbances elsewhere.** The tilt (loop 9's
  actuator) shifts heat between *every* absorbing surface; the FD vanes
  (loop 2) load the furnace pressure that loop 4 holds. The loop pages
  trace these couplings.

## Reading the code with this map

`ControlSystem.derivatives` computes the table top to bottom: each
loop's block forms its error, applies PI gains, sums feedforwards, and
deposits an integrator derivative and a lag derivative — the
[two primitive elements](@basics/control-basics) — into `xdot(23..46)`.
The signal names encode their loop (`c*md` master, `c*ar` air, `c*fl`
fuel, `c*fn` furnace, `c*gr` recirc, `c*ft` FP turbine, `c*fv`
feedwater, `c*dv` deaerator, `c*rh` reheat, `c*sy` superheat, `c*tr`
turbine), so any line in the method locates itself in this table.

::: caution
The model omits the plant's *discrete* automation — trips, runbacks,
interlocks, burner management. Test 7 notes this explicitly (no Unit
Run-Back on fan loss). The eleven loops are the *modulating* layer
only: what runs the plant between emergencies, and what the thesis'
emergency tests probe the limits of.
:::

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| all eleven loops | `ControlSystem.derivatives` (states 23–46) | `model.ControlSystem` |
| actuator commands | `ControlSystem.actuatorCommands` | `model.ControlSystem` |
| boiler-following override | `k4pss = 2415` constant set point | `ControlSystem.derivatives` |
| loop gains / time constants | `kc*`, `ktc*` families | `model.Parameters` |
:::

Next: [Combustion-side loops](@plant/loops-combustion) — master, air,
fuel, furnace pressure and recirculation in detail.
