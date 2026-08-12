---
description: Three end-to-end walkthroughs — drum pressure, the swing equation with its units audit, and the reheat loop from sensor to flame — every step from physics to MATLAB.
---

# Equation to code, three walkthroughs

Everything on this site converges here. Three complete traces — a
thermodynamic state, a mechanical equation, a control loop — each
followed from first principles to the exact lines of MATLAB, with
nothing skipped. If these three read easily, the model is yours.

## 1. Where a drum pressure trace comes from

Test 1's drum pressure falls and recovers. No equation in the model
says $\dot p_{drs} = \ldots$ — so where does the trace come from?

**Physics:** the drum stores water and steam at saturation; its
pressure is a *property* of its contents, not a state
([two-property rule, tightened](@basics/thermo-properties)).

**States:** water volume and steam density
([the pair](@plant/waterwalls-drum)). Their derivatives come from net
mass and energy imbalances — every flow crossing the drum boundary:

```matlab
sig.z206 = sig.wfw - sig.wrw + sig.wwwo - sig.wdrs - sig.wdrbd;
sig.z209 = sig.wwwo*sig.hwwo - (sig.wrw - sig.wfw)*sig.hdrw ...
    - sig.wdrs*sig.hdrs - sig.wdrbd*sig.hdrs;
```

**The solve:** phase change inside the boundary couples the two states,
so the derivatives are solved [jointly](@code/vessels):

```matlab
[sig.f1dr, sig.f2dr] = model.VesselDynamics.saturatedVessel( ...
    P.kvdr, s.vdrw, s.rdrs, ..., sig.z206, sig.z209);
xdot(4) = sig.f1dr;      % water volume
xdot(5) = sig.f2dr;      % steam density
```

**The pressure:** pure output — the saturation fit evaluated at the
integrated density, each logging instant:

```matlab
ps = 11.1877 + 500.267*rs - 26.4031*rs2 + 0.46944*rs3;   % drumSaturation
```

So the trace you plot is: *flows → imbalances → joint solve →
integrate density → saturation fit → pressure.* Five stages, no
pressure state anywhere — and shrink/swell falls out of the same
chain for free.

## 2. The swing equation, with the units audit

**Physics:** Newton for the rotor, with the grid's
[electromagnetic spring](@basics/generator-grid) as the load:

$$J\,\dot\omega = T_{\mathrm{turb}} - T_{\mathrm{gen}}
\qquad
T = \frac{P}{\omega}$$

**Code**, both states:

```matlab
xdot(16) = (sig.mwtro - sig.mwgn)/(s.ntr*P.kjtre);   % swing equation
xdot(47) = s.ntr - g.nelec;                           % power angle
```

with the spring law and the [turbine sum](@basics/turbines) upstream:

```matlab
mwgn = kn2*kmwr*sin(delta);
sig.mwtro = sig.mwhp + sig.mwip + sig.mwlp;   % each: w*(dh)*P.kj
```

**The audit** — run the units through, as the
[units page](@basics/units) taught: `mwtro` carries `P.kj` = 778.17
ft·lbf/Btu, so powers are in ft·lbf/s. Divide by speed (rad/s):
torque in lbf·ft. Divide by inertia — which must therefore be in
**slug·ft²**: lbf·ft / (slug·ft²) = rad/s². Dimensionally forced,
which is exactly how the as-listed `kjtre = 625000` (lbm·ft², vendor
$WR^2$) was convicted: in this equation it is off by $g_c$, and the
model ships the corrected value:

```matlab
kjtre = 625000/32.174; % units correction, see docs/model.md
```

One equation, and it exercises the unit system, the turbine sum, the
spring law, and the repository's most consequential bug fix.

## 3. The reheat loop, sensor to flame

The longest signal path in the plant: a temperature 300 feet from the
burners, controlling the angle of the flames. Sensor to actuator,
every line:

**Measure and schedule** ([control practices](@basics/control-practices)):

```matlab
ctrho = xd(P.ktrhol, P.ktrhou, P.kcl, P.kcu, sig.trho);  % to 1-5 V
ktrh  = P.k1trh + P.k2trh*sig.whp;                       % scheduled set point
ktrh  = chk(ktrh, P.k4trh, P.k3trh);                     % clamped to band
kctrh = xd(P.ktrhol, P.ktrhou, P.kcl, P.kcu, ktrh);      % set point, in volts
```

**Error and PI** ([control basics](@basics/control-basics)):

```matlab
c3rh = c1rh + c2rh - ctrho;      % error (c1rh = kctrh; c2rh = stubbed ff)
c4rh = c3rh*P.kc1rh;             % proportional
c5rh = lim(s.c5rh);              % integrator state, clamped copy
c6rh = c4rh + c5rh;              % PI sum
xdot(33) = c4rh/P.ktc1rh;        % the integrator integrates the P term
```

**Demand lag** (state 42, [the actuator the plant sees](@code/state-vector)):

```matlab
xdot(42) = (cxgg - u.cxggd)/P.ktc2rh;   % cxgg = clamped PI output
```

**Command** ([actuatorCommands](@code/control-system)):

```matlab
u.xgg = xd(P.kcl, P.kcu, P.kxggl, P.kxggu, u.cxggd);   % volts -> +-30 deg
```

**Physics** ([the furnace](@plant/furnace) feels it):

```matlab
sig.uxgg  = P.k1xgg + P.k2xgg*sin(u.xgg)/cos(u.xgg);   % radiant multiplier
sig.uwwgm = P.kuwwgm*sig.uxgg*sig.ungg;
qwwgm = uwwgm*(twwge4 - twwm4);                        % heat moves
```

Less radiant absorption means hotter gas to the
[convective banks](@code/heat-transfer), the reheater warms, `trho`
rises, the error closes — around the loop in five files, perhaps two
minutes of plant time. And orbiting it: the
[recirculation integrator](@plant/loops-combustion) watching `u.xgg`
against its ±5° deadband, ready to take over the steady part.

## Where to go from here

Run the tests and read the traces with these three chains in mind.
Then pick any line of `PowerPlant.m` this site never quoted — by now
you can name its balance, its units, and its page. That was the goal.
