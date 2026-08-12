---
description: The square-root law relating flow to pressure drop, valves as variable resistances, and how the model solves whole flow networks in closed form.
---

# Pressure-driven flow

Balances say what accumulates; properties say what the fluid is. The
missing third ingredient is *motion*: given the pressures around the
plant, how much water and steam actually flows? The model's answer is a
single law used dozens of times, plus a strategy for combining it across
networks of pipes, valves and vessels.

::: why
Flows are what couple the control volumes together — every $w$ in every
[balance equation](@basics/mass-energy-balances) comes from a flow
relation. Master the square-root law and its combinations and you can
read all of `Hydraulics.m` and most of the flow lines in `PowerPlant.m`.
:::

## The square-root law

Push fluid through any restriction — an orifice, a stretch of pipe, a
valve — and the pressure drop grows with the *square* of the flow (fluid
momentum and turbulence both scale that way). The model writes every
restriction in that form:

::: equation Friction law of a restriction
$$\Delta p \;=\; k_f\,\frac{w^2}{\rho}
\qquad\Longleftrightarrow\qquad
w \;=\; \sqrt{\frac{\Delta p\;\rho}{k_f}}$$
:::

with $w$ the mass flow (lbm/s), $\rho$ the fluid density at the
restriction, and $k_f$ a **friction coefficient** — one number
summarizing the restriction's geometry, taken from the thesis data deck
(`kfps`, `kfrh`, `kfec`, … in `Parameters`). Denser fluid carries more
mass for the same pressure drop; a tighter restriction (larger $k_f$)
carries less. In code, with one refinement:

```matlab
function w = orificeFlow(r, pd, kf)      % thesis SHFLOW
    kd1 = 1;
    if pd < 0        % flow follows the pressure gradient, either way
        pd = -pd;
        kd1 = -1;
    end
    w = kd1*sqrt(pd*r/kf);
end
```

The sign dance matters: during transients a pressure difference can
momentarily reverse, and $\sqrt{\Delta p}$ of a negative number is not a
crash you want at 2 a.m. of a long simulation. The model preserves the
direction explicitly: flow goes down the gradient, whichever way that
points.

## Valves: resistances you can vary

A valve is the same law with an adjustable opening. The model folds the
opening into the coefficient as an **area factor** $a \in [0, 1]$:

::: equation Valve flow
$$w \;=\; k_v\, a \,\sqrt{p\,\rho}$$
:::

Here is the most important valve in the plant — the turbine throttle,
taking main steam at pressure `psso` and density `rsso`, with the
governor-commanded area `acv`:

```matlab
sig.wtv = P.kcv*sig.acv*sqrt(sig.psso*s.rsso);
```

Every controllable flow in the model looks like this: the control system
outputs an area (through the actuator lags you met in the
[state page](@basics/state-variables)), and the physics turns area times
conditions into flow. This line is *the* interface between the
controllers and the plant.

## Networks: restrictions in series and parallel

Real flow paths are chains: feed pump → feedwater valve → HP (high
pressure) heaters → economizer → drum, each stage with its own
resistance. Two rules combine them:

- **Series** (same $w$ through all): pressure drops add, so the $k_f$
  values simply add — a chain collapses to one equivalent restriction.
- **Parallel** (same $\Delta p$ across all): flows add.

Because every element is quadratic in $w$, an entire series-parallel
network reduces to a *quadratic equation* in the unknown flow — and
quadratics have closed-form solutions. That is the design principle of
`Hydraulics.m`: rather than iterate ("guess flow, check pressures,
adjust"), each network is reduced by hand to its quadratic and solved
exactly, once, every evaluation. Fast, and — like the polynomial fits —
smooth for the integrator.

::: definition Flow network solve
Given source pressures at both ends (say, deaerator and drum), pump
head gains in between (next page), and the summed resistances, the
network solve finds the one flow at which all the gains and losses
balance. In the model these are the functions `feedwater`,
`condensate`, `recirculation` and `airGas` in `Hydraulics.m` — one per
major loop.
:::

## Steam too, with a caveat

Gases are compressible — their density changes along the path — and
rigorous compressible flow is much harder than the square-root law. The
model applies the same law to steam and flue gas anyway, evaluating
$\rho$ at local conditions. For the moderate pressure *ratios* across
any single restriction in this plant, that is a sound engineering
approximation; it would break for chokes and shocks, which this plant's
normal and emergency envelopes do not reach.

::: caution
The friction coefficients bundle unit conversions along with geometry —
they are data-deck constants tuned for lbm/s, psia and lbm/ft³, and are
not transferable to other unit systems without rework. Treat each $k_f$
as *this plant's* number, not a material property.
:::

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| square-root law | `orificeFlow(r, pd, kf)` | `model.Hydraulics` |
| throttle/governor valve | `sig.wtv = P.kcv*sig.acv*sqrt(...)` | `model.PowerPlant` |
| network solves | `feedwater`, `condensate`, `recirculation`, `airGas` | `model.Hydraulics` |
| friction coefficients | `kfps`, `kfss`, `kfrh`, `kfec`, … | `model.Parameters` |
:::

Next: [Pumps and fans](@basics/pumps-fans) — the components that *create*
the pressure differences everything else consumes.
