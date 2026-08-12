---
description: Feedback, error, proportional and integral action, and the actuator lag — the four ideas behind all 24 control states.
---

# Feedback control basics

The plant's other 24 states belong to its controllers. Remarkably, they
are built from just two primitive dynamic elements — the **integrator**
and the **first-order lag** — arranged around one idea: feedback. This
page builds that idea from zero to exactly the depth the model uses.

::: why
Eleven control loops, 24 states, and every single one is "PI controller
feeding an actuator lag" in some costume. Learn the costume once and
`ControlSystem.m` — the model's longest file — becomes eleven variations
on one theme.
:::

## Feedback and error

Open-loop control — compute the right valve position from a model and
hope — fails in a plant where everything drifts. **Feedback** replaces
hope with measurement:

::: definition The feedback loop
Measure the controlled variable, subtract from its **set point** to form
the **error** $e = r - y$, compute an actuator command from the error,
act, and let the plant's response change the measurement. Errors, not
plans, drive everything.
:::

## Proportional action, and its flaw

The simplest law: push proportionally to the error, $u = K_p\,e$. Larger
error, harder push — reasonable, and the model's loops all have a
proportional term. But pure P control has a structural flaw: to hold
*any* nonzero actuator output it needs *nonzero error*. If the boiler
needs 80 lbm/s of fuel to hold pressure, a P-only pressure controller
must sit at some pressure offset forever to command it. The plant would
run, permanently a little off every set point.

## Integral action: memory kills offset

The fix is a term that accumulates:

::: equation PI (proportional–integral) control
$$u \;=\; K_p\,e \;+\; K_i \int_0^t e\,d\tau$$
:::

The integral keeps growing while any error persists — so the *only*
possible steady state is $e = 0$: the integrator ratchets the command
until the error is exactly gone, then holds it. That stored integral is
a state (it is *memory*, as the [state page](@basics/state-variables)
defined it), and it is why the plant returns to exactly 2415 psia after
every load change. Twelve of the 24 control states are these
integrators. In the model's style, here is the reheat temperature loop
forming its error and its integrator:

```matlab
c3rh = c1rh + c2rh - ctrho;        % error: set point minus measurement
c4rh = c3rh*P.kc1rh;               % proportional gain
c5rh = lim(s.c5rh);                % the integrator STATE (clamped copy)
c6rh = c4rh + c5rh;                % PI sum
...
xdot(33) = c4rh/P.ktc1rh;          % integrator: accumulates the P term
```

(The thesis wires PI as "integrate the proportional term" — algebraically
the same law, with $K_i = K_p/\tau_{c1}$.)

## The actuator lag

Controllers command; hardware obeys *sluggishly*. A valve drive, a vane
positioner, a fuel skid — each takes seconds to follow its demand. The
model represents every actuator with the simplest possible dynamic, the
**first-order lag**:

::: equation First-order lag
$$\tau\,\frac{dy}{dt} \;=\; u - y$$
:::

The output chases the command; the **time constant** $\tau$ is the
chase's timescale (63% of the way there in $\tau$ seconds). Ten of the
24 control states are these lags — one per actuator, with time constants
from the data deck (fuel 5 s, vanes 5 s, gas recirc 20 s, …):

```matlab
xdot(36) = (c6fl - u.cfld)/P.ktc2fl;   % fuel demand lag, tau = 5 s
```

The lag states are the *demands* the plant actually sees — `cfld`,
`card`, `cxggd`, … — the very signals the
[flow page](@basics/fluid-flow) turned into valve areas.

## Saturation, and the windup it causes

Real actuators have ends of travel. The model clamps every control
signal to its working range, and clamping an *integrator* creates a
classic pathology:

::: definition Integrator windup
If the actuator saturates while error persists, the integrator keeps
accumulating a command the hardware cannot deliver. When conditions
finally improve, the wound-up integral must unwind before the actuator
moves off its limit — the plant overshoots or hangs at the rail. The
model's boiler-master integrator (`c3md`) winds up without bound in
Tests 6 and 7 (the pressure set point is unreachable); its *clamped
copy* is what acts, so behavior stays correct while the raw state grows.
:::

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| PI integrators (12 states) | `xdot(23–34, 44)` pattern `= cXyz/P.ktc1yz` | `model.ControlSystem` |
| actuator lags (10 states) | `xdot(35–43, 46)` pattern `= (cmd − state)/tau` | `model.ControlSystem` |
| clamping | `limchk` (1–5 V), `check` (arbitrary bounds) | `model.ControlSystem` |
| time constants | `ktc1*`, `ktc2*` families | `model.Parameters` |
:::

Next: [Power-plant control practices](@basics/control-practices) — the
plant-specific craft: normalized signals, scheduled set points,
cross-limits and deadbands.
