---
description: The load reference, the 5% droop, and the governor valves — the loop that spends stored steam and ties the plant's output to grid frequency.
---

# Turbine control and the governor

The eleventh loop is the fastest and the most consequential: it decides
what the plant *delivers*. Three states (44/45/46) stand between the
load demand `ldc` and the governor valve area `agv` — and one of its
terms quietly makes the plant a frequency-supporting citizen of the
grid.

::: why
Every test trajectory starts here: the governor moves within seconds of
any demand or frequency change, spending the boiler's stored energy
long before the [combustion side](@plant/loops-combustion) can brew
more. Its droop term is also the only place the plant *voluntarily*
responds to grid frequency — everything else just suffers it.
:::

## The load reference

Demand `ldc` is compared with *generated power* (`mwtro`, transduced to
the control scale), and the error drives the **load reference motor**
(state 44, `c2tr`) — a rate-limited integrator, so named because the
1970s hardware was literally a motor turning a potentiometer. The rate
limit (`kmrl`) is why commanded load moves as a ramp, never a step: the
plant accepts load changes only as fast as its steam supply deserves. A
demand lag (state 45, `c4tr`) smooths the reference on its way to the
valve arithmetic.

## The droop

Added to the load reference is a speed term:

::: equation Governor droop
$$\Delta(\text{valve demand}) \;=\; -\,\frac{n_{tr} - n_{\mathrm{set}}}{R},
\qquad R = k_{cvreg} = 0.05$$
:::

Five percent droop — the industry-standard proportional speed
regulation. Read it as a promise to the grid: *if frequency falls 5%,
this machine opens fully; every 0.1% dip earns 2% more output.* Droop
is deliberately proportional-only (no integrator): thousands of
generators share frequency support, and each must yield a predictable
share rather than fight to correct frequency alone. When Test 6 drags
the grid down 6.7%, it is this term that slams the governor to its 5 V
rail within seconds — the model's fastest large signal excursion.

## The valve

Reference plus droop, clamped, becomes the governor valve demand
`cacvd` (state 46, the final actuator lag) and then the valve area
`agv` — the [throttle law](@basics/fluid-flow) that admits steam to the
[steam chest](@plant/turbine-train). End to end, `ldc` to steam flow:
one rate-limited integrator, one lag, one droop sum, one valve. The
speed asymmetry this creates — turbine in seconds, boiler in minutes —
is the entire reason the
[boiler-following architecture](@plant/control-room) exists.

## What it cannot do

The governor can only *release* energy the boiler has stored. Test 4
(ramp to 100%) shows the ceiling: valves wide open, demand unmet,
pressure sagging — the loop rails and waits for combustion. And the
intercept valve (`aiv`), nominally this loop's colleague for overspeed
duty, stays wide open in every modeled scenario: the model carries the
speed-protection *plumbing* but no trip logic, consistent with the
modulating-only [control-room scope](@plant/control-room).

::: metrics The loop at 100% load
| Quantity | Value |
|---|---|
| Droop | 5% (`kcvreg = 0.05`) |
| Speed set point | 377 rad/s (`kntr`) |
| States | 44 (reference), 45 (lag), 46 (valve demand) |
| Actuator | governor valve area `agv` ← `cacvd` |
:::

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| power measurement | `cmwtro` transducer from `mwtro` | `ControlSystem.derivatives` |
| load reference + rate limit | `c2tr`, `kmrl` | `ControlSystem.derivatives` |
| droop | `kcvreg` speed term | `ControlSystem.derivatives` |
| valve demand | `cacvd` → `agv` | `ControlSystem.actuatorCommands` |
:::

Next: [The seven emergency tests](@plant/emergency-tests) — everything
on this site, run against the thesis' scenarios.
