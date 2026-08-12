---
description: The 600 MW synchronous machine in operation — pull-out margins, what the swing pair does in every test, and the auxiliary bus that makes the whole plant a grid citizen.
---

# Generator and grid

The [physics page](@basics/generator-grid) built the electromagnetic
spring; this page operates it. One synchronous machine couples the
[turbine train](@plant/turbine-train) to the infinite bus — and through
the auxiliary bus, the *grid couples back* into every motor in the
plant. Reading the plant's emergency behavior is largely reading this
one machine's two states.

::: why
Nothing else in the plant can destroy it as fast. Boiler transients
play out over minutes; a generator losing synchronism pole-slips in
under a second. The margins on this page — power angle, pull-out
torque — are the hard electrical limits inside which every other page's
dynamics must live.
:::

## The operating point

At 100% load the machine runs at 377 rad/s (3600 rpm — a two-pole
machine at 60 Hz) with power angle $\delta = 30°$. That angle is the
single most informative number on the electrical side:

::: equation Loading and margin
$$P_{\mathrm{gen}} = P_{\max}\sin\delta
\quad\xrightarrow{\;\delta = 30°\;}\quad
P_{\mathrm{gen}} = \tfrac12 P_{\max}$$
:::

Rated load uses exactly *half* the machine's synchronizing capability —
pull-out sits at twice rated power. That factor-of-two margin is what
lets the machine absorb load swings, voltage dips and frequency
excursions without slipping; and it is precisely the margin that the
[kjtre units error](@basics/units) fictitiously consumed — with an
inertia 32× too large, Test 6's deceleration demanded more torque than
pull-out could supply, and the simulated machine slipped poles where
the real one (and the corrected model) rides through.

## The swing pair across the seven tests

States 16 (`ntr`) and 47 (`delta`) in action:

| Test | What the pair does |
|---|---|
| 1–4 (load ramps) | `delta` glides between equilibria (`asin` of load); `ntr` flat within ±0.1 rad/s — the spring at work |
| 5 (voltage dip) | main machine barely notices (the bus voltage term affects auxiliaries, not the modeled spring); the story is in the motors |
| 6 (frequency ramp) | `ntr` dragged 377 → 352 rad/s by the grid; the pair's undamped ring visible after the ramp ends |
| 7 (fan-pair loss) | power falls to what air allows; `delta` re-seats ≈14° lower; speed flat |

The pair's undamped oscillation (≈1.8 rad/s) never decays in the model
— in trajectories you will see it as a fine, persistent ripple on
`ntr` after any sharp disturbance. That is not a bug; it is the
thesis' declared modeling choice, and the reason the
[trim tool pins the pair](@basics/state-variables) rather than waiting
for it to settle.

## The auxiliary bus: the grid inside the plant

The model's second electrical fact hides in plain sight: `velec` and
`nelec` feed **every induction motor** — recirculation, condensate, FD,
ID. One bus (4160 V), one frequency, no local generation modeled. So a
grid disturbance arrives *twice*: once at the generator (through the
spring) and once at every auxiliary (through
[motor torque](@basics/rotating-machinery), $\propto V^2$ and slip).
Test 5 is *purely* the second path: the machine itself shrugs at a 30%
voltage dip, but the fans and pumps sag, and the steam side feels the
grid through them. Real plants segment their auxiliaries across buses
with transformers and ride-through logic; the thesis' single-bus
simplification is exactly what makes its emergency tests clean
experiments.

## Power bookkeeping, once more

Three power numbers coexist in the model and are easy to conflate:

- `mwtro` — mechanical power the turbines deliver (ft·lbf/s
  internally, [for torque](@basics/turbines));
- `mwgn` — electrical power the *grid draws* through the spring
  ($P_{\max}\sin\delta$): the swing equation's other side;
- `mwo` — the display/logging output in watts (`mwtro·kmwx`).

At equilibrium the first two agree; during every transient their
difference is exactly what accelerates the shaft.

::: metrics The machine at 100% load
| Quantity | Value |
|---|---|
| Rating / speed | 600 MW at 377 rad/s (3600 rpm, 2-pole) |
| Power angle / pull-out margin | 30° / 2× rated |
| Auxiliary bus | 4160 V, common to all motors |
| Swing mode | ≈1.8 rad/s, undamped by design |
:::

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| swing pair | `xdot(16)`, `xdot(47)` | `model.PowerPlant` |
| spring law | `mwgn = kn2·kmwr·sin(delta)` | `model.PowerPlant` |
| auxiliary coupling | `nelec`, `velec` into every `inductionMotor(...)` | `PowerPlant.machines` |
| scenario grid | `GridProfile.test5/test6` | `model.GridProfile` |
:::

Next: [The control system at a glance](@plant/control-room) — the
eleven loops that run all of the above without an operator.
