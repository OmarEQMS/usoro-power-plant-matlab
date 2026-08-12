---
description: The synchronous generator as an electromagnetic spring — power angle, the swing equation, the infinite bus, and why an undamped oscillator sits at the heart of the model.
---

# The generator and the grid

Every page so far ends at a shaft. This one connects the biggest shaft —
the 600 MW turbine–generator — to the electrical grid, through the one
piece of machinery whose physics is *qualitatively* unlike a motor's: the
**synchronous generator**. Its model is two equations, and they hide the
most numerically treacherous dynamics in the whole plant.

::: why
States 16 and 47 — turbine speed and power angle — form an *undamped
oscillator*. That single fact once forced an early port of this model to
freeze both states to survive, and it dictates the integration scheme to
this day. Understanding the electromagnetic spring is prerequisite to
understanding both the plant's behavior in grid emergencies and the
model's numerics.
:::

## The infinite bus

The plant does not power the grid; it *joins* it. Against the combined
inertia of every other generator on the interconnection, this one
machine cannot move the grid's frequency or voltage measurably. The
model therefore treats the grid as an **infinite bus**: a fixed 60 Hz,
4160 V boundary condition — adjustable only by scenario
(`GridProfile`), as in Tests 5 and 6.

## The electromagnetic spring

A synchronous generator's rotor is an electromagnet spinning inside
windings tied to the bus. Rotor and bus field rotate at the same average
speed — synchronously — and the rotor can only lead the bus field by an
angle, the **power angle** $\delta$. Electrical power transferred grows
with the sine of that lead:

::: equation Generator power transfer
$$P_{\mathrm{gen}} \;=\; P_{\max}\,\sin\delta$$
:::

```matlab
mwgn = kn2*kmwr*sin(delta);
```

Lead further, transmit more — up to $\delta = 90°$, the **pull-out**
limit, beyond which more angle transmits *less* power and the machine
slips poles. Below pull-out, the behavior is exactly a torsional
spring: nudge the rotor ahead and it pushes power out (restoring
torque); let it lag and it pulls power in. The generator holds turbine
speed at 377 rad/s not by friction but by this spring — what the thesis
calls the machine's *electromagnetic spring action*.

## The swing equations

Attach the spring to the rotor's torque balance and you get the model's
famous pair — states 16 and 47:

::: equation The swing pair
$$\frac{d\,n_{tr}}{dt} = \frac{P_{\mathrm{turb}} - P_{\mathrm{gen}}}{n_{tr}\,J_{tre}}
\qquad\qquad
\frac{d\,\delta}{dt} = n_{tr} - n_{elec}$$
:::

```matlab
xdot(16) = (sig.mwtro - sig.mwgn)/(s.ntr*P.kjtre);   % swing equation
xdot(47) = s.ntr - g.nelec;
```

Mass (the rotor inertia) plus spring (the $\sin\delta$ power law) equals
an oscillator — here at about 1.8 rad/s, a ~3.5 second period. And the
thesis makes a deliberate modeling choice: **no damping term**. Real
machines have damper windings; the thesis judged their effect negligible
against the mechanical system and dropped them. The result is an
oscillator that, once excited, rings *forever* in the model —
mathematically marginal, physically defensible, numerically a landmine:

- **Integration:** an undamped oscillation is the acid test of an
  integrator. Explicit Euler *amplifies* it every step, unconditionally
  — the [numerical integration page](@basics/numerical-integration)
  shows why this exact pair forced an early port to freeze both states.
- **Trimming:** a mode that never decays never settles; finding steady
  state requires pinning the pair by hand ($n_{tr} = n_{elec}$,
  $\delta = \arcsin(P_{\mathrm{turb}}/P_{\max})$ — precisely what the
  trim tool does).

## Grid emergencies through the spring

The swing pair turns grid disturbances into plant transients:

- **Frequency drop (Test 6):** the grid ramps 60 → 56 Hz and the spring
  drags the whole turbine train down with it — 377 → 352 rad/s in five
  seconds. Whether the machine *can* follow depends on deceleration
  torque versus the pull-out limit: with the as-listed (uncorrected)
  inertia the required torque exceeds pull-out and the model slips
  poles; with the corrected $WR^2/\gc$ inertia it rides through exactly
  as the thesis' figure shows. The [units page's](@basics/units) trap,
  resolved by this page's physics.
- **Load changes (Tests 1–4):** power demanded from the governor changes
  the turbine torque; $\delta$ glides to the new $\arcsin$; speed barely
  moves. The spring is why turbine speed stays within ±0.1 rad/s through
  a 135 MW load ramp.

::: metrics The machine at 100% load
| Quantity | Value |
|---|---|
| Speed | 377.0 rad/s (60 Hz × 2π) |
| Power angle $\delta$ | 0.524 rad ≈ 30° |
| Swing frequency | ≈1.8 rad/s (period ≈3.5 s) |
| Inertia constant H (corrected) | ≈2.7 s |
| Bus voltage | 4160 V |
:::

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| swing pair (states 16, 47) | `xdot(16)`, `xdot(47)` | `model.PowerPlant` |
| power transfer | `mwgn = kn2*kmwr*sin(delta)` | `model.PowerPlant` |
| grid boundary | `GridProfile.nominal/test5/test6` | `model.GridProfile` |
| swing-pair pinning at trim | `settleAndPin` | `src/tools/trim_operating_points.m` |
:::

Next: [Feedback control basics](@basics/control-basics) — the other 24
states: how the plant steers itself.
