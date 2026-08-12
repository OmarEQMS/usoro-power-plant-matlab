---
description: Two methods carry all eleven loops — actuatorCommands turning demand states into physical commands, and derivatives computing the 24 control states, block by thesis block.
sourceFile: src/+model/ControlSystem.m
---

# ControlSystem.m

The model's longest method lives here, and it is long for an honest
reason: eleven control loops, transcribed block by block from the
thesis' Chapter IV diagrams, each block keeping its
[thesis name](@code/conventions). Two public methods split the work at
a natural seam.

::: why
This file is where the [1–5 V world](@basics/control-practices) is
implemented — every transducer, limiter, cross-limit and deadband on
this site's control pages is a specific line here. It is also the file
you subclass for control experiments, so its seams matter.
:::

## Seam one: `actuatorCommands`

```matlab
u = ctrl.actuatorCommands(s)
```

Before the plant can be evaluated, the ten
[demand-lag states](@code/state-vector) must become physical commands:
clamp each demand to its rails (`limchk`), pass it through its
[linear transducer](@basics/control-practices) (`xducer`), and emit
the result — valve areas, tilt angle, flows — as the `u` struct the
[plant consumes](@code/power-plant). This method is *pure signal
conditioning*: no dynamics, no set points, just the 1–5 V ↔ physical
mappings and their hard limits. It is also where the plant's safety
envelope physically lives — whatever the loops ask for, `u` never
exceeds the transducer ranges.

## Seam two: `derivatives`

```matlab
xdotCtrl = ctrl.derivatives(s, u, sig, ldc)
```

Inputs tell the architecture: the control states (`s`), the
conditioned commands (`u`), the plant's measurements (`sig` — the bus
again), and the scenario demand (`ldc`). Inside, the eleven loops run
in a fixed order — boiler master first (it feeds air and fuel), then
combustion, water, temperatures, turbine — each block computing its
error, PI (proportional–integral) terms and feedforwards with the
thesis' block numbering (`c1rh`, `c2rh`, …), and depositing exactly
two kinds of derivative at the end:

```matlab
xdot(33) = c4rh/P.ktc1rh;               % a PI integrator
xdot(42) = (cxgg - u.cxggd)/P.ktc2rh;   % an actuator lag
```

Twelve integrators, ten lags, one rate-limited reference, one demand
lag — [the full roster](@code/state-vector). The
[loop pages](@plant/control-room) document each block's purpose;
against them, the method reads as a checklist.

## The configuration surface

Four public properties modify behavior without subclassing:

- `gasRecircEnabled` — the [deadband loop's](@plant/loops-combustion)
  master switch; Tests 6 and 7 set it `false`, as the thesis did;
- `fc2dv`, `fcp1st`, `fctrho`, `fcxgg` — the
  [stubbed rate feedforwards](@basics/control-basics), zero by
  default; supply them from a subclass or script to experiment with
  the thesis' d/dt compensation.

For deeper experiments, subclass and override `derivatives` — the
plant never knows. The boiler master's [set-point
override](@basics/control-practices) (`k4pss = 2415`, boiler-following)
is the first thing a coordinated-mode experiment would remove.

## Helpers worth knowing

Three tiny static methods appear hundreds of times: `limchk` (clamp to
1–5 V), `check` (clamp to arbitrary bounds — thesis CHECK argument
order), and the `xducer` linear map. They are the entire vocabulary of
[saturation](@basics/control-basics) in this model — every rail in
every test trace is one of these calls binding.

::: caution
Integrator states are *not* clamped — their limited copies act
(`c5rh = lim(s.c5rh)` and kin), so integrators
[wind up](@basics/control-basics) freely while saturated (`c3md` in
Tests 6/7 famously so). This is faithful to the thesis code; treat
large integrator excursions in trajectories as saturation telemetry,
not as bugs.
:::

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| signal conditioning | `actuatorCommands(s)` | `src/+model/ControlSystem.m` |
| the eleven loops | `derivatives(s, u, sig, ldc)` | `src/+model/ControlSystem.m` |
| config properties | `gasRecircEnabled`, `fc*` | `src/+model/ControlSystem.m` |
| helpers | `limchk`, `check`, `xducer` | `src/+model/ControlSystem.m` |
:::

Next: [Simulator, profiles and initial conditions](@code/simulator) —
the machinery that turns $f(t,x)$ into trajectories.
