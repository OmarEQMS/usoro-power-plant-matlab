---
description: Explicit Euler and why it lies about oscillators, RK4 and its stability region, and the 0.1-second step this model inherits from 1977 — with the real bug story that proves the stakes.
---

# Numerical integration

Everything is assembled: $\dot x = f(t,x)$, all 47 rows of it. The last
tool is the humblest-looking and the easiest to get catastrophically
wrong — marching the solution forward in time. This page covers the two
schemes that matter to this model: the one that breaks it, and the one
it uses.

::: why
This is not background — it is a load-bearing choice. An early port of
this very model used a scheme equivalent to explicit Euler, watched the
turbine–generator oscillation grow without bound, and "fixed" it by
hard-coding both swing states to zero — freezing the shaft speed for
every simulation. The integrator you choose decides which physics you
are allowed to keep.
:::

## The idea: small steps

No formula gives $x(t)$ for a nonlinear system, but $f$ tells us the
slope *right now*. So: take the state, step a small $h$ along the slope,
repeat. All integrators are refinements of this; they differ in how they
estimate the slope across the step.

## Explicit Euler — and its lie

The simplest scheme uses the slope at the step's start:

::: equation Explicit Euler
$$x_{k+1} \;=\; x_k + h\,f(t_k, x_k)$$
:::

Cheap, intuitive — and *systematically outward-spiraling* on
oscillations. See it on the ideal oscillator (the
[swing pair's](@basics/generator-grid) essence), whose solution circles
in the plane of (speed, angle). Euler steps along the *tangent* of the
circle — and every tangent step leaves the circle, landing slightly
outside. Per step, the amplitude multiplies by

::: equation Euler's amplification of an undamped mode
$$|1 + i\,\omega h| \;=\; \sqrt{1 + \omega^2 h^2} \;>\; 1
\quad\text{— always, for any step size.}$$
:::

No step is small enough: shrinking $h$ slows the spiral but never stops
it. An undamped oscillation under explicit Euler *will* grow until it
wrecks the run — which is exactly what the frozen-speed port
experienced, and why its author froze states 16 and 47. The lesson
deserves italics: *the instability was not in the plant model; it was in
the integrator.* The physics was right and the numerics called it wrong.

## RK4: probe before you leap

The classic fourth-order Runge–Kutta method spends four slope
evaluations per step — start, two midpoint probes, end — and blends
them:

::: equation RK4
$$x_{k+1} = x_k + \tfrac{h}{6}\big(k_1 + 2k_2 + 2k_3 + k_4\big)$$
:::

```matlab
[k1, sig, u] = obj.derivative(t, x);
k2 = obj.derivative(t + h/2, x + (h/2)*k1);
k3 = obj.derivative(t + h/2, x + (h/2)*k2);
k4 = obj.derivative(t + h, x + h*k3);
x = x + (h/6)*(k1 + 2*k2 + 2*k3 + k4);
```

That is `Simulator.step`, verbatim — and it is also, to the step size,
exactly what the thesis' own integration program (DYSYS) did in 1977.
The blend buys two things: fourth-order *accuracy* (halving $h$ cuts
error ~16×), and — decisive here — a **stability region that includes
the imaginary axis** up to $|\omega h| \le 2\sqrt2$. Undamped
oscillations neither grow nor shrink (a hair of numerical damping,
nothing more) as long as the step resolves them.

Check the plant's numbers: swing mode $\omega \approx 1.8$ rad/s, step
$h = 0.1$ s $\Rightarrow \omega h = 0.18$ — fifteen times inside the
limit. The swing pair that destroys Euler is a comfortable passenger
under RK4. The margin also covers the model's faster machinery modes,
which is what actually sizes the step.

## Why a fixed step

Modern practice often reaches for adaptive integrators (`ode45` and kin)
that grow and shrink $h$ against an error estimate. This model
deliberately uses fixed-step RK4 at $T_s = 0.1$ s:

- **Fidelity to the thesis** — same scheme, same step, comparable
  trajectories; the model's job is replication.
- **Non-smooth right-hand side** — the
  [limiters, deadbands and selectors](@basics/control-practices) put
  corners in $f$. Error estimators trip on corners and grind the step
  down chasing accuracy that isn't there; a fixed step just walks
  through.
- **Determinism** — every run of a scenario takes identical steps,
  which makes regression comparisons exact rather than approximate.

The price is honesty about resolution: events much faster than 0.1 s are
not resolved. Nothing in the plant's modeled physics is.

::: caution
If you hand `sim.derivative` to an adaptive solver anyway (it is a pure
function; nothing stops you), expect chattering near the control
limiters and remember that trajectories will no longer match the
thesis' step-for-step. For validated work, stay with `Simulator.run`.
:::

## The toolkit, complete

You now hold every tool the model is built from: units that don't lie,
balances that generate the physics, properties and fits that close them,
flow and machine laws that couple them, control structures that steer
them, and an integrator that tells the truth about all of it. The
[Power Plant section](@plant/overview) now walks the real machine with
these tools in hand.

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| RK4 step | `Simulator.step(t, x)` | `model.Simulator` |
| fixed step $T_s$ | `Ts = 0.1` property | `model.Simulator` |
| full run loop | `Simulator.run(x0, tEnd)` | `model.Simulator` |
| the frozen-speed history | archived pre-RK4 port | `deprecated/` (audit trail) |
:::
