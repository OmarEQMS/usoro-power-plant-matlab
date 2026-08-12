---
description: The 1-5 V signal world, linear transducers, scheduled set points, air/fuel cross-limits and deadbands — the plant-control craft the model reproduces from 1970s hardware.
---

# Power-plant control practices

[PI control and lags](@basics/control-basics) are textbook. What makes a
*power plant's* control system is the craft wrapped around them —
conventions and safety structures developed over decades of analog
hardware. The model reproduces them faithfully, because the thesis
modeled a real plant's cabinets. Four practices explain nearly every
odd-looking line in `ControlSystem.m`.

::: why
Signals like `cfld = 4.56` make no sense until you know the 1–5 V
convention; lines like `kwgr = kc2gr*wfl` make no sense until you know
cross-limiting. These practices are the difference between reading the
control code and decoding it.
:::

## One signal world: 1–5 V

Analog control rooms standardized every signal — any pressure, any flow,
any temperature — onto one electrical range so that any instrument could
talk to any controller. This plant uses **1–5 V** (the electronic twin
of the pneumatic 3–15 psi standard; the live zero at 1 V distinguishes
"measuring zero" from "dead wire"). The mapping is the **linear
transducer** (thesis XDUCER):

::: equation Linear transducer
$$c \;=\; c_{\min} + (c_{\max} - c_{\min})\,
\frac{z - z_{\min}}{z_{\max} - z_{\min}}$$
:::

Every physical range gets its pair of deck constants: fuel flow 0–90
lbm/s maps to 1–5 V (`kwfll`, `kwflu`), throttle pressure 0–3015 psia
likewise (`kpssol`, `kpssou`), and so on for every measured variable.
So `cfld = 4.56` V *is* 80 lbm/s of fuel, and all 24 control states live
on this one scale — which is also why the model clamps signals to
[1, 5]: the rails of the electronics are the limits of authority.

## Scheduled set points

Some set points should themselves move with load. Steam temperature is
the classic: at low load the reheater cannot reach 1000 °F without
overfiring, so its set point is *scheduled* — computed from a load
signal rather than fixed. The model schedules both temperature set
points on HP steam flow (using the
[first-stage-pressure flow meter's](@basics/turbines) cousin, `whp`),
clamped to a working band:

```matlab
ktrh = P.k1trh + P.k2trh*sig.whp;        % reheat set point, R
ktrh = chk(ktrh, P.k4trh, P.k3trh);      % clamp to [1259.67, 1459.67] R
```

At full load the schedule sits above the 1000 °F clamp — so the set
point *is* 1000 °F; below ≈52% flow the schedule takes over and the
plant deliberately runs its reheat cooler.

## Cross-limiting: air leads fuel

Burning fuel without enough air fills the furnace with unburned fuel —
then any spark means an explosion. Combustion control therefore enforces
an asymmetry, the **air/fuel cross-limit**:

- the **air** demand takes the *maximum* of (boiler demand, current fuel
  flow) — air may always increase, and must never be below what current
  fuel needs;
- the **fuel** demand takes the *minimum* of (boiler demand, current
  measured air) — fuel may never exceed what current air can burn.

On load increases air rises first and fuel follows; on decreases fuel
falls first and air follows. The plant can be slow; it must never be
rich. You will meet these `max`/`min` selectors in the air and fuel
loops, and their consequences in every capability-limited test: when
air saturates (Tests 4, 6, 7), the cross-limit is what holds fuel — and
therefore megawatts — down.

## Deadbands: don't chase noise

Some actuators shouldn't respond to every flicker. The gas recirculation
integrator only runs while the burner tilt is *outside* a ±5° deadband:

```matlab
kcgr = P.kn0;                                    % integrator off...
if obj.gasRecircEnabled && abs(u.xgg) > P.knp087 % ...unless tilt beyond 5 deg
    kcgr = P.kn1;
end
xdot(27) = c1gr*P.kc1gr*kcgr;
```

Inside the band, the recirc flow simply *stays where it is*. The cost of
this peace: the steady state is no longer unique — where the recirc
freezes depends on the transient that brought you there. This model's
77.5% operating point genuinely has a *band* of equilibria, a
directly observable consequence of a deadband wrapped around an
integrator.

## The mode this plant runs in

All eleven loops are coordinated under **boiler-following** logic: the
governor takes load directly (fast, spending stored steam), and the
boiler master watches throttle pressure fall and re-fires to restore it
(slow, making new steam). The alternative — coordinated mode, where a
scheduled pressure set point moves with load — exists in the code but is
overridden to a constant 2415 psia, exactly as the thesis ran every
published test.

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| linear transducer | `xducer(zmin, zmax, cmin, cmax, z)` | `model.ControlSystem` |
| range constants | `kwfll/kwflu`, `kpssol/kpssou`, … | `model.Parameters` |
| scheduled set points | `ktrh`, `ktss` from `sig.whp` | `ControlSystem.derivatives` |
| air/fuel cross-limits | max/min selectors, air & fuel loops | `ControlSystem.derivatives` |
| recirc deadband | `abs(u.xgg) > P.knp087` gate | `ControlSystem.derivatives` |
:::

Next: [Numerical integration](@basics/numerical-integration) — the last
tool: how to march $\dot x = f(t,x)$ forward without lying.
