---
description: Pump and fan curves, the affinity rules, and how the model finds each loop's operating point — the intersection of machine curve and system resistance — in closed form.
---

# Pumps and fans

The [square-root law](@basics/fluid-flow) only *spends* pressure — every
restriction dissipates it. Something must create it. Six rotating
machines pressurize this plant's loops: a feed pump (with its booster), a
recirculation pump, a condensate pump, and the FD (forced draft) and ID
(induced draft) fans — two of each, normally. This page is about how a
spinning machine turns speed into pressure, and how the model finds the
flow where machine and system agree.

::: why
Five of the model's states are pump/fan shaft speeds, and their loops
supply every flow the balances consume. The machine-curve picture on
this page is also what makes the plant's *electrical* emergencies
matter: grid trouble slows motors, slower machines make less pressure,
and less pressure ripples into every balance in the plant. Tests 5, 6
and 7 are all, at bottom, this page's physics.
:::

## The machine curve

A centrifugal pump or fan at speed $n$ generates a pressure rise that is
highest at zero flow and droops as flow increases. Over its working
range the curve is well captured by a quadratic in flow and speed:

::: equation Machine curve (pump or fan)
$$\Delta p_{\mathrm{machine}} \;=\; a\,n^2 \;+\; b\,n\,w \;-\; c\,w^2$$
:::

The three coefficients are the machine's fingerprint, fitted from the
manufacturer's test curves. In the model they appear as constant
triples — here, the main feed pump and its booster inside
`Hydraulics.feedwater`:

```matlab
k1fp = -57.3012e-3; k2fp = 959.4371e-6; k3fp = 203.8473e-6;
k4fp = -1.735761e-3; k5fp = 129.1779e-6; k6fp = 548.9264e-9;
k1bp = -2.63447e-3;  k2bp = 200.721e-6;  k3bp = 99.9049e-6;
```

The shape encodes the two limits you should carry as intuition: at
**shutoff** (no flow) the machine holds its maximum head, proportional
to $n^2$; at **runout** (max flow) it holds none. Real operation lives
between them.

::: definition Affinity rules
Scale a centrifugal machine's speed and its curve scales predictably:
flow $\propto n$, pressure rise $\propto n^2$, shaft power
$\propto n^3$. The $n^2$ in the machine curve *is* the affinity rule —
and it is why modest speed losses hurt: a motor dragged 5% slow by a
grid disturbance gives up ~10% of its head.
:::

## The operating point: where curve meets system

Connect the machine to its circuit — the system's resistances, from the
[flow page](@basics/fluid-flow), plus any static pressure difference it
must overcome (pumping into a 2778 psia drum, say). The system consumes:

::: equation System curve
$$\Delta p_{\mathrm{system}} \;=\; k_{f,\mathrm{total}}\,\frac{w^2}{\rho}
\;+\; \Delta p_{\mathrm{static}}$$
:::

The loop settles where generation meets consumption:
$\Delta p_{\mathrm{machine}} = \Delta p_{\mathrm{system}}$. Both sides
are quadratics in $w$, so the intersection is again a closed-form
quadratic solve — the same design principle as the flow networks, and in
fact it *is* the flow-network solve: each function in `Hydraulics.m`
bundles its loop's machine curves and resistances and solves for the one
flow where everything balances, returning the flow, the intermediate
pressures, and the machine's efficiency for the torque bookkeeping:

```matlab
[wfp, wfw, wfw2, pbpo, pfpo, pfvo, phho, pfvd, efp] = ...
    feedwater(wry, wsy, rdew, pdes, pdrs, reco, afv, nfp)
```

Note what varies between calls: the feedwater valve area `afv` (a control
action reshaping the system curve) and the pump speed `nfp` (a state
reshaping the machine curve). The operating point moves instant by
instant as both change — this function is evaluated fresh at every
derivative call.

## Fans: same physics, gas numbers

The FD and ID fans obey the same curve mathematics with flue-gas
densities a thousandth of water's. Their circuit is the furnace: FD fans
push combustion air in through the air heater; ID fans pull flue gas out
through the convective passes and stack, holding the furnace itself just
below atmospheric pressure (14.7 psia set point) so combustion gas leaks
*inward*, not into the building. Their control handles are inlet **vane
areas** (`avf`, `avi`) — again areas from the control system, reshaping
resistance. The pair count matters: normally two FD + two ID fans share
the duty; Test 7 removes one pair and the survivors must carry the whole
system curve alone — at, per machine, roughly double flow toward runout.

## Machine speeds at full load

::: metrics Shaft speeds, 100% load (rad/s)
| Machine | Speed | Driven by |
|---|---|---|
| Feed pump (+ booster) | 542.2 | steam turbine (extraction steam) |
| Recirculation pump | 187.2 | induction motor |
| Condensate pump | 186.6 | induction motor |
| FD fans | 61.9 | induction motors |
| ID fans | 92.5 | induction motors |
:::

Four of the five are motor-driven — their speeds ride on grid voltage
and frequency, which is exactly the coupling the electrical emergency
tests exploit. The feed pump is the exception: it is driven by its own
small *steam turbine*, fed with extraction steam, making it immune to
grid sags but tied to the steam cycle's health instead. Both drive
mechanisms get their dynamics on the
[rotating machinery page](@basics/rotating-machinery).

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| pump curves | `k1fp…k6fp`, `k1bp…k3bp` (local) | `Hydraulics.feedwater` |
| fan curves + furnace circuit | `airGas(knfd, knid, nfd, nid, …)` | `model.Hydraulics` |
| operating-point solves | `feedwater`, `condensate`, `recirculation`, `airGas` | `model.Hydraulics` |
| machine speeds (states 1, 6, 17, 21, 22) | `nfp`, `nrp`, `ncp`, `nfd`, `nid` | `model.StateVector` |
:::

Next: [Turbines and expansion work](@basics/turbines) — the machines that
run the cycle in reverse: consuming pressure to *make* shaft power.
