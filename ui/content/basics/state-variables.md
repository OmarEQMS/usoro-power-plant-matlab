---
description: What a dynamic system is, what state variables are, why the plant model is one big first-order ODE system, and what "47th order" actually means.
---

# States, systems and ODEs

The entire power plant model is a single mathematical object:

$$\dot x = f(t, x)$$

— one vector function that, given the current time and the current state
of the plant, returns how fast every part of that state is changing. Every
page after this one is really just filling in pieces of $f$. This page
makes sure the object itself is solid ground: what a state is, what an
ODE (ordinary differential equation) system is, and what it means that
this plant is *47th order*.

::: why
Almost everything confusing about the model code — why there is exactly
one derivative function, why it must not modify anything, why initial
conditions matter so much, why "steady state" is a special condition you
must *search* for — follows directly from the mathematical shape
$\dot x = f(t,x)$. Learn the shape once and the code becomes predictable.
:::

## Systems with memory

Some systems are pure functions of their inputs: an amplifier's output
now depends on its input now. Physical plants are not like that. If you
suddenly close a valve, boiler pressure does not jump to a new value — it
*evolves*: the boiler keeps producing steam, mass accumulates, pressure
climbs over seconds and minutes. The plant has **memory**: its response
depends not only on what you do now but on everything that happened
before, summarized in the amounts of mass and energy currently stored
inside it.

::: definition State
The **state** of a system is a minimal set of numbers that summarizes its
entire history: knowing the state now and the inputs from now on, you can
predict everything about the future. For physical plants, states are
almost always *stored quantities* — masses, energies, momenta — or
quantities standing in for them, like densities, enthalpies,
temperatures and speeds.
:::

Concrete examples from this plant:

- the **drum steam density** ($r_{drs}$) — how much steam is packed into
  the drum's steam space right now;
- the **waterwall metal temperature** ($t_{wwm}$) — how much heat the
  furnace-wall steel is currently holding;
- the **turbine–generator speed** ($n_{tr}$) — the rotational momentum of
  a 300-ton shaft;
- a **controller integrator** — yes, controllers have memory too: a PI
  (proportional–integral) controller's integral term is a stored number
  that remembers accumulated error. That is why control states count as
  states with exactly the same standing as physical ones.

## The equation of motion: $\dot x = f(t,x)$

Stack all the state variables into one column vector $x$. The model's
physics (and its controllers) then say how each stored quantity changes
*right now* as a function of what is stored *right now*:

::: equation The state-space form
$$\dot x \;=\; \frac{dx}{dt} \;=\; f(t,\, x)$$
:::

Two features of this form deserve emphasis:

- **$f$ has no memory of its own.** Everything historical lives in $x$.
  Evaluating $f$ twice at the same $(t, x)$ must give the same answer —
  in code terms, the derivative function is *pure*, with no side effects.
- **Time appears only through the inputs.** The plant's physics do not
  care what o'clock it is; $t$ enters because the *scenario* does — the
  load demand $ldc(t)$ ramping down, the grid voltage stepping at
  $t = 10$ s. In this model all explicit time dependence comes from the
  scenario profiles, never from the plant equations themselves.

::: definition Order of a system
The **order** is the number of state variables — the length of $x$. This
model has $x \in \mathbb{R}^{47}$: it is a 47th-order system, meaning 47
first-order ODEs advancing together, every one potentially coupled to
every other.
:::

The 47 break down as **23 physical states** (stored masses, energies and
momenta of the boiler, turbines, heaters, vessels and rotors) and **24
control-system states** (eleven loops' worth of PI integrators and
actuator lags). The full annotated list lives in the Code section:
[StateVector.m and the 47 states](@code/state-vector).

## Higher-order equations hide inside

You may have met differential equations written with second derivatives,
like Newton's law for an oscillator: $m\ddot z = -kz$. The state-space
form has no second derivatives — and needs none, because any higher-order
equation converts to first-order form by naming the derivatives as extra
states. The plant's own turbine–generator is the perfect example. Its
swing dynamics are second-order in the rotor angle, and the model carries
them as two first-order states — the speed and the angle:

::: equation The swing pair, in first-order form
$$\frac{d\,n_{tr}}{dt} = \frac{T_{\mathrm{turb}} - T_{\mathrm{gen}}}{J}
\qquad\qquad
\frac{d\,\delta}{dt} = n_{tr} - n_{elec}$$
:::

Speed $n_{tr}$ is state 16; angle $\delta$ is state 47. Every "second
derivative" in the thesis becomes a pair like this in the model.

## Initial conditions: where integration starts

An ODE system does not single out one trajectory — it defines a *family*
of them, one for every possible starting point. To simulate, you must
supply the starting state:

::: definition Initial condition
An IC (initial condition) is the full state vector $x(0)$ at the start of
a run. Given $x(0)$ and the input profiles, the trajectory $x(t)$ is
uniquely determined — that is the initial-value problem.
:::

The model ships one canonical IC: the thesis' published 100%-load state —
all 47 numbers, from drum steam density to the last controller
integrator. Starting anywhere else means starting mid-transient: the
plant will spend its first minutes settling *your* arbitrary choice, not
responding to your scenario.

## Equilibrium: when nothing moves

::: definition Equilibrium (steady state)
A state $x^{\ast}$ is an **equilibrium** under constant inputs if
$f(t, x^{\ast}) = 0$ — every stored quantity's rate of change is zero, so the
plant sits still. Power plants at constant load are designed to operate
at equilibria.
:::

Equilibria are *found*, not declared. Setting a load level does not tell
you the 47 numbers that make everything balance — you must search for the
state where $f$ vanishes. This model finds its 77.5% and 50% operating
points by **trimming**: integrating at constant load demand until the
transients die away, then cleaning up what remains. Two subtleties make
this more interesting than "run it and wait":

- one mode of the plant (the swing pair above) is *undamped* — it
  oscillates forever and must be pinned to its equilibrium exactly;
- one control loop (gas recirculation) has a deadband, so a **band** of
  slightly different equilibria exists and the one you land on depends on
  the path you took. "The" steady state is not always unique.

## Nonlinearity — why we simulate instead of solve

Linear ODE systems ($\dot x = Ax$) have closed-form solutions. This model
is decisively nonlinear: flows go as $\sqrt{\Delta p\,\rho}$, furnace
radiation as $T^4$, generator power as $\sin\delta$, and control signals
saturate at hard limits. There is no formula for $x(t)$ — the only way to
get a trajectory is to march it forward numerically, step by step. How
that is done safely (and how doing it unsafely once broke this very
model) is the subject of [Numerical integration](@basics/numerical-integration).

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| state vector $x$ | 47×1 double column | `model.StateVector` indices/unpack |
| $f(t,x)$ | `sim.derivative(t, x)` | `model.Simulator` (plant + control) |
| initial condition $x(0)$ | `model.InitialConditions.at100()` | thesis 100% state |
| trimmed equilibria | `ic775.mat`, `ic50.mat` | `src/tools/trim_operating_points.m` |
:::

Next: [Mass and energy balances](@basics/mass-energy-balances) — where the
rows of $f$ actually come from.
