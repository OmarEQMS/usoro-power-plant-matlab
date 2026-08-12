---
description: How the model turns the steam tables into pure arithmetic — local polynomial fits, their validity ranges, and the transcription story that shows why physics must audit the math.
---

# Steam tables and polynomial fits

The [previous page](@basics/thermo-properties) established the
two-property rule: know two properties of steam and the rest are
determined. But *determined how*? Water's real property relations are
wildly nonlinear and have no exact formulas — they live in the **steam
tables**, decades of measurements compiled into reference books. A
simulation stepping 10 times a second cannot page through a book. This
page is about the model's answer: replace each lookup with a small
polynomial, fitted once, valid locally.

::: why
Every coefficient like `-21.3442` in `SteamTables.m` is a piece of a
steam table, compressed. Knowing how the fits were made tells you what
they can and cannot do: they are excellent *interpolators* near their
component's operating range and unreliable *extrapolators* outside it —
a distinction that decided a real debugging story in this model.
:::

## From table to polynomial

Take the drum. It lives on the saturation curve, so one property fixes
all (the tightened two-property rule). The thesis chose the steam
density $\rho_{drs}$ as the anchor — it is a state of the model, always
at hand — and fitted every needed saturation property as a low-order
polynomial in it. The result is the entire drum property model:

```matlab
function [rw, hw, hs, ps, Ts] = drumSaturation(rs)   % thesis DRSTAT
    rs2 = rs*rs;
    rs3 = rs2*rs;
    rw = 49.27105 - 2.13733*rs + 0.03348*rs2;          % water density
    hw = 526.5957 + 31.0437*rs - 0.62086*rs2;          % water enthalpy
    hs = 1241.713 - 21.3442*rs + 0.20998*rs2;          % steam enthalpy
    ps = 11.1877 + 500.267*rs - 26.4031*rs2 + 0.46944*rs3;  % pressure
    Ts = 458.084 + 48.2088*rs - 3.2326*rs2 + 0.07249*rs3 + 459.67;
end
```

Five curve fits, three multiplications of overhead, no lookup. In 1977
this was the difference between a simulation that ran and one that did
not; today it still buys the model its speed and — just as valuable —
its *smoothness*: polynomials have clean derivatives, which numerical
integration appreciates.

::: definition Curve fit (regression)
Choose a functional form (here: polynomials, occasionally with a cross
term like $\rho \cdot h$), take known table points spanning the range you
care about, and pick coefficients minimizing the mismatch. The fit
*interpolates* reliably inside that range; outside it, the polynomial
follows its own algebra, not water's.
:::

## Local by design

Notice what the drum fit does **not** try to do: describe water
everywhere. It describes saturation properties for roughly
2400–3000 psia — the drum's neighborhood — and that is typical of all
sixteen fits: each is tailored to one component's operating window.

That is why the model has *sixteen* property functions instead of one
general water model: superheated fits for the superheater's window,
another pair for the reheater's lower pressures, saturation fits for the
drum and (a much lower-pressure set) for the deaerator, compressed-liquid
fits for feedwater. Same substance, different neighborhoods,
different polynomials.

::: caution
Local fits fail *quietly*. Evaluate `drumSaturation` at a density far
from its window and it returns confident nonsense — no error, no NaN
(Not a Number), just wrong numbers with plausible magnitudes. When a
simulation drives a component outside its normal range (a deep emergency
transient, say), fit validity is one of the first things to question.
:::

## When two readings disagree, physics arbitrates

The fits also star in this model's best debugging story. The cross-over
fit (thesis CRSTAT) computes the IP (intermediate pressure) turbine
exhaust state via an isentropic reference (the pattern from the
[properties page](@basics/thermo-properties), developed fully on the
[turbines page](@basics/turbines)):

```matlab
hi = -1211.8 + 683.58*r + 1384.39*s;   % isentropic reference enthalpy
ho = h1 - ef*(h1 - hi);                % actual exhaust enthalpy
```

The thesis was scanned from a 1977 typescript, and in the scanned
FORTRAN the second line is ambiguous: `H1` or `HI`? One reading anchors
the expansion at the inlet enthalpy (correct); the other at the
isentropic reference (wrong). Both produce running simulations. The tie
was broken by physics, not typography:

- with the wrong reading, the computed cross-over state landed at
  126 psia *below saturation temperature* — superheated steam that is
  somehow colder than boiling: impossible;
- with the right reading, the feed pump turbine's torque balance closes
  against the thesis' own published numbers to four significant digits.

The lesson generalizes: **every fit output has physical bounds, and
checking them is how transcription errors die.** A property function is
never just math — it makes claims about water that water can veto.

## What a modern model would do

Today one would reach for the international standard water-property
formulation — IAPWS-IF97 — a set of carefully constructed equations
covering all of water's regions with guaranteed accuracy. The model
keeps the 1977 fits deliberately: this repository's purpose is to
reproduce the thesis, and the fits *are part of the thesis' physics*,
offsets and all.

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| the 16 fits | `drumSaturation` … `reheatSprayMix` | `model.SteamTables` |
| saturation fits (1 input) | `drumSaturation`, `deaeratorSaturation`, `heaterSteamSat`, `heaterWaterSat` | `model.SteamTables` |
| superheated fits (2 inputs) | `superheatedSteam`, `reheatSteam` | `model.SteamTables` |
| the CRSTAT anchoring choice | `crossoverSteam` (comment tells the story) | `model.SteamTables` |
:::

Next: [Pressure-driven flow](@basics/fluid-flow) — the other half of the
plant's algebra: given pressures, what flows?
