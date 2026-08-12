---
description: Torque balances for rotors, induction motors and slip, the steam-driven feed pump — and why six of the model's states are shaft speeds.
---

# Rotating machinery

Six of the plant's states are shaft speeds: the turbine–generator, the
feed pump, the recirculation and condensate pumps, and the FD (forced
draft) and ID (induced draft) fans. Each obeys the same law — Newton for
rotors — with its own cast of torques. This page builds that law, the
induction-motor torque that drives four of the six, and the load torques
the pumps push back with.

::: why
Shaft speeds are where the *electrical* world enters the model: motor
torque depends on grid voltage and frequency, so a grid disturbance
reaches the steam cycle through these six equations. Tests 5, 6 and 7
are all stories about this page's torque balances.
:::

## Newton for rotors

::: equation Rotor torque balance
$$J\,\frac{d\omega}{dt} \;=\; T_{\mathrm{drive}} - T_{\mathrm{load}}$$
:::

$J$ is the rotational inertia (slug·ft² — recall the
[units page's](@basics/units) $WR^2/\gc$ trap), $\omega$ the speed in
rad/s, and the torques in lbf·ft. Steady speed means torques balanced;
any imbalance integrates into acceleration. Here is the condensate
pump's balance exactly as the model states it:

```matlab
xdot(17) = (sig.tqcp1 - sig.wcp*(sig.pcpo - sig.pcn)*P.kn144/ ...
    (s.ncp*sig.rcno*sig.ecp))/P.kjcp;
```

Drive torque `tqcp1` from the motor, minus the **pumping load torque** —
which is just power over speed: the pump's hydraulic power is flow times
pressure rise over density, $w\,\Delta p/\rho$ (the 144 converts psi to
lbf/ft²), divided by the pump efficiency `ecp` from the
[network solve](@basics/pumps-fans), divided by $\omega$. All over the
inertia `kjcp`. Every pump and fan speed equation in the model has this
identical anatomy.

## The induction motor

Four of the six shafts are turned by induction motors — the workhorse
machine of every power plant's auxiliaries. The physics the model keeps
is minimal and sufficient:

::: definition Slip
An induction motor develops torque only by lagging the grid's rotating
field. The **slip** is the fractional lag,
$s = (n_{\mathrm{sync}} - n)/n_{\mathrm{sync}}$, where the synchronous
speed $n_{\mathrm{sync}}$ is set by grid frequency (and the motor's pole
count). Zero slip, zero torque; normal full-load slip is a few percent.
:::

Near normal operation, torque is proportional to slip — and, crucially,
to **voltage squared** (torque comes from the stator field acting on
currents that field itself induces — both scale with $V$):

::: equation Induction motor torque, operating region
$$T \;\propto\; V^2 \, s$$
:::

```matlab
[sig.tqcp1, sig.mwcp1] = model.Turbomachinery.inductionMotor( ...
    sig.nelec, sig.velec, P.kncpm, s.ncp, P.kcpm, P.scpmax);
```

The two grid inputs are right there in the call: `nelec` (frequency →
synchronous speed) and `velec` (voltage). Now the emergency tests
explain themselves. **Test 5** (30% voltage drop): torque falls to
$0.7^2 = 49\%$ at unchanged load → every motor slips deeper and settles
slower and slightly slow. **Test 6** (frequency 60 → 56 Hz): synchronous
speed itself drops 6.7% and every motor-driven machine follows it down,
fans included — and with fans slowed, air, fuel and ultimately megawatts
are capped. The model's per-motor slip limit (`scpmax` etc.) caps torque
at the pull-out region, matching how real motors let go.

## The odd one out: the steam-driven feed pump

The feed pump — the machine forcing 1100+ lbm/s into a 2778 psia drum,
consuming ~10 MW — is driven not by a motor but by its own auxiliary
**steam turbine**, fed with extraction steam:

```matlab
[sig.tqfp1, sig.mwfp1] = model.Turbomachinery.feedpumpTurbine(u.wft, sig.hft1, s.nfp);
```

Its torque comes from steam flow `wft` (a control-system output) and the
steam's enthalpy, not from the grid — so in Test 5 the feed pump sails
through untouched while every motor around it sags. The price: its
drive depends on the steam cycle being healthy, a circularity (steam
drives the pump that feeds the boiler that makes the steam) that the
plant's designers accepted for the efficiency and the grid immunity.
It was also this torque balance, closing to four digits against the
thesis' numbers, that settled the CRSTAT reading — the feed pump turbine
drinks cross-over steam, so its power output is a sensitive audit of the
cross-over enthalpy.

## Inertia sets the tempo

How fast does each machine respond? The torque balance's time scale is
$J\omega/T$ — inertia times speed over torque. The plant's rotors span
three decades: the condensate pump (`kjcp` = 468) settles in a second or
two; the big fans (`kjfd` ≈ 182,000; `kjid` = 188,000) take tens of
seconds — their slow coast-down is the visible dynamics of Tests 5 and
7 — and the turbine–generator (`kjtre` ≈ 19,400 after the units
correction) carries the whole plant's kinetic buffer. That machine is
special for another reason too: it is locked to the grid by an
electromagnetic spring, which changes its dynamics qualitatively — the
subject of the [next page](@basics/generator-grid).

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| torque balances (states 1, 6, 17, 21, 22) | `xdot(1), xdot(6), xdot(17), xdot(21), xdot(22)` | `model.PowerPlant` |
| induction motor | `inductionMotor(nelec, velec, knm, n, km, smax)` | `model.Turbomachinery` |
| feed pump turbine | `feedpumpTurbine(wft, hft1, nfp)` | `model.Turbomachinery` |
| rotor inertias | `kjcp`, `kjrp`, `kjfd`, `kjid`, `kjfpe`, `kjtre` | `model.Parameters` |
:::
