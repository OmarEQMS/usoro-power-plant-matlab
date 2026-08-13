---
description: Simulator assembles plant + control + scenario into f(t,x) and marches it with RK4; LoadProfile, GridProfile and InitialConditions supply the scenario and the starting point.
sourceFile:
  - src/+model/Simulator.m
  - src/+model/LoadProfile.m
  - src/+model/GridProfile.m
  - src/+model/InitialConditions.m
---

# Simulator, profiles and initial conditions

Four small classes turn the model into *runs*: `Simulator` owns the
integration loop, `LoadProfile` and `GridProfile` own the scenario
inputs, and `InitialConditions` owns the starting point. Between them
they are everything the [numerical integration
page](@basics/numerical-integration) promised.

::: why
This is the layer you actually call. Every test, every trim, every
dashboard session is: build a `Simulator` from parts, hand it an
initial state, run. Knowing its three public methods — `derivative`,
`step`, `run` — is knowing the model's entire API surface.
:::

## Assembly

```matlab
sim = model.Simulator(plant, ctrl, model.LoadProfile.test1(), ...
                      model.GridProfile.nominal());
```

The constructor takes the two machines and the two scenario profiles
(both defaulting to steady 100% / healthy grid). The profiles are
trivial by design — function handles wrapped in value classes —

```matlab
prof = model.LoadProfile(@(t) 5 - 0.0125*max(0, min(t - 10, 90)));
grid = model.GridProfile(@(t) 376.991, @(t) 4160*(1 - 0.3*(t >= 10)));
```

— so *any* scenario is one lambda, and the named constructors
(`test1()`…`test4()`, `test5()`, `test6()`) are just the thesis'
scenarios prebuilt. All explicit time dependence in the model
[enters here](@basics/state-variables), nowhere else.

## The three methods

**`derivative(t, x)`** — assembles $f(t,x)$: unpack, actuator
commands, grid sample, plant, plus control derivatives. The
[tour](@code/tour) walked its five lines; everything since has been
their contents.

**`step(t, x)`** — one [RK4](@basics/numerical-integration) step of
`Ts = 0.1` s: four derivative calls, the classic blend, then two
pieces of thesis stepping semantics. After the blend, the control
states are saturated in place (`ControlSystem.clampStates`) — the
FORTRAN's by-reference limiter calls, i.e. the integrators'
[anti-windup](@basics/control-basics). And the first (committed)
derivative call advances the
[rate-feedforward](@plant/loops-steam) backward differences. One
convenience with consequences: it returns the `sig` and `u` evaluated
at the *incoming* point, so callers (the dashboard, the logger) get
the pre-step signals without paying a fifth evaluation.

**`run(x0, tEnd)`** — the loop: preallocate, step, log. Returns
everything a study needs:

```matlab
res = sim.run(model.InitialConditions.at100(), 700);
res.t          % time vector (every step)
res.X          % 7001 x 47 state history
res.log        % 1 Hz signal log, 25 columns
res.logNames   % {'t','ntr','mwo','psso',...}
```

The 25 log columns are the thesis' standard plot set — `plotStandard`
arranges them into the six 2×2 figures matching the thesis' V.x figure
layout, which is how every "matches Figure V.n" claim on this site is
eyeballed.

## Initial conditions

`InitialConditions.at100()` is the thesis' p. 288 state — all 47
values, the only *published* equilibrium. The trimmed 77.5% and 50%
points ship as `.mat` files produced by
`src/tools/trim_operating_points.m`, which is a study in this layer's
API: it runs ramps with one profile, settles with another
(`LoadProfile.constant`), integrates a damped variant of
`sim.derivative` to kill the [undamped swing
ring](@basics/generator-grid), and pins the pair exactly. Custom
operating points follow the same recipe.

::: caution
`run` logs at 1 Hz but *stores every state at every step* — `res.X`
for a 700 s run is 7001×47 doubles (~2.6 MB). Cheap for studies,
worth knowing before you script thousand-run sweeps.
:::

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| assembly + RK4 + logging | `model.Simulator` | `src/+model/Simulator.m` |
| scenario inputs | `LoadProfile`, `GridProfile` | `src/+model/` |
| starting points | `InitialConditions`, `ic775/ic50.mat` | `src/+model/` |
| trimming recipe | `trim_operating_points.m` | `src/tools/` |
:::

Next: [Tests and the dashboard](@code/tests-and-app) — the entry
points built on this API.
