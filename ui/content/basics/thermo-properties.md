---
description: Pressure, temperature, density, enthalpy and entropy; phases, saturation and quality; the two-property rule that shapes every steam-table call in the model.
---

# Thermodynamic properties of water

The plant is a machine for pushing one substance — water — around a loop
while changing its condition: compressed, boiled, superheated, expanded,
condensed. To follow the model you need to speak water's language: a
handful of **properties**, the rules connecting them, and the map of
water's phases. No derivations here; just the working vocabulary and the
one structural rule that organizes all of it.

::: why
Every steam-table function in the model — all sixteen of them — is an
answer to the same question: "given what I know about the steam here,
what is everything else?" The **two-property rule** on this page explains
why those functions take the arguments they take, and why the saturated
ones take one argument fewer. Learn the rule and the code's signatures
stop being arbitrary.
:::

## The property vocabulary

A property is a number describing the *local condition* of the water —
not how it got there, not how fast it is moving through the pipe.

::: definition The five you will meet constantly
**Pressure** $p$ (psia) and **temperature** $T$ (°R) you know.
**Density** $\rho$ (lbm/ft³) — mass packed per volume; the model's
favorite stored quantity. **Specific enthalpy** $h$ (Btu/lbm) — energy
content per pound, defined below. **Specific entropy** $s$
(Btu/(lbm·°R)) — the expansion-accounting property, defined last.
:::

Enthalpy deserves its definition, because the
[energy balances](@basics/mass-energy-balances) leaned on it:

::: equation Specific enthalpy
$$h \;=\; u \;+\; \frac{p\,v}{J}$$
:::

Internal energy $u$ plus the **flow work** $p\,v$ — the work a stream
does pushing its way into or out of a volume ($v = 1/\rho$ is specific
volume; $J = 778.17$ ft·lbf/Btu converts the mechanical term into Btu).
Enthalpy exists so that "energy carried by a flowing stream" is a single
number: $w \cdot h$. When a table says main steam has $h = 1460$ Btu/lbm
and feedwater has $h = 478$, the boiler's job — the heat it must supply
per pound — is the difference, 982 Btu/lbm. This kind of arithmetic is
most of thermodynamics as practiced.

## Phases and the saturation curve

At a given pressure, water can be:

- **Subcooled (compressed) liquid** — colder than boiling at that
  pressure. Feedwater everywhere upstream of the boiler.
- **Saturated mixture** — *at* the boiling point, part liquid, part
  vapor, temperature locked while the fractions change. Inside the drum
  and the deaerator.
- **Superheated vapor** — hotter than boiling at that pressure. Main
  steam, reheat steam, everything through the turbines.

The boundary is the **saturation curve** $p_{sat}(T)$: each pressure has
exactly one boiling temperature. At atmospheric 14.7 psia water boils at
212 °F; at the drum's ≈2778 psia it boils near 680 °F. The curve *ends*
at the **critical point**, 3206 psia and 705 °F, where liquid and vapor
become indistinguishable — this plant's drum runs at 87% of critical
pressure, which is why its steam and water densities are much closer
together than intuition suggests (9.4 vs ≈28 lbm/ft³), and why drum
behavior is subtler than "steam floats on water".

::: definition Quality
In a saturated mixture, the **quality** $x$ is the vapor mass fraction:
$x = m_{\mathrm{vap}}/(m_{\mathrm{vap}} + m_{\mathrm{liq}})$. Mixture
properties interpolate between the saturated-liquid and saturated-vapor
values, e.g. $h = h_f + x\,(h_g - h_f)$. The model meets quality at the
LP (low pressure) turbine exhaust, where steam leaves ≈7% wet, and in the
drum's steam-water bookkeeping.
:::

## The two-property rule

Here is the structural fact that organizes every property computation:

::: equation The state postulate, working form
$$\text{For water in a single phase: fixing } \textbf{two}
\text{ independent properties fixes } \textbf{all} \text{ the rest.}$$
:::

Know $(\rho, h)$ of superheated steam and $p$, $T$, $s$ are all
determined — no history, no geometry, just water being water. And on the
saturation curve the rule tightens: saturation itself uses up one degree
of freedom, so **one** property fixes everything (know the pressure and
you know the boiling temperature, both phase densities, both phase
enthalpies).

This is exactly the shape of the model's steam-table functions:

```matlab
% superheated regions: two in -> the rest out
[p, T, s] = model.SteamTables.superheatedSteam(r, h);   % thesis SHSTAT
% saturated vessels: ONE in -> everything out
[rw, hw, hs, ps, Ts] = model.SteamTables.drumSaturation(rs);  % thesis DRSTAT
```

The superheater tracks two states (density and enthalpy — the mass and
energy balances from the [previous page](@basics/mass-energy-balances))
and computes its pressure and temperature from them. The drum tracks its
steam density and gets *five* properties back from that single number,
because the drum lives on the saturation curve. When you reach the Code
section's [SteamTables page](@code/steam-tables), every signature will
read as an application of this rule.

## Entropy and ideal expansion

Entropy is the property whose *constancy* defines the perfect turbine.
An expansion that is adiabatic (no heat lost) and frictionless keeps $s$
constant; real machines are compared against that ideal:

::: equation Isentropic reference
$$h_i \;=\; h(p_{\mathrm{out}},\, s_{\mathrm{in}})
\qquad\text{— the enthalpy if expansion kept } s \text{ constant}$$
:::

A real turbine stage delivers a fixed *fraction* of the ideal enthalpy
drop — its isentropic efficiency. That single idea powers the model's
whole turbine chain, and it is developed properly in
[Turbines and expansion work](@basics/turbines). For now, entropy is: the
number you hold constant to compute what expansion could ideally do.

## The enthalpy ladder

Numbers make the loop concrete. Approximate specific enthalpies around
the water path at 100% load:

::: metrics Enthalpy around the loop (100% load, Btu/lbm)
| Station | $h$ |
|---|---|
| Condensate leaving LP heaters | 199 |
| Feedwater after HP heaters | 478 |
| Economizer outlet | 635 |
| Main steam at the throttle (2415 psia, 1000 °F) | 1460 |
| HP turbine exhaust (cold reheat) | 1317 |
| Hot reheat (1000 °F again) | 1519 |
| IP exhaust / cross-over | 1380 |
| LP exhaust into the condenser (≈93% quality) | ≈1000 |
:::

Read the ladder and the plant's whole strategy appears: heat water up
982 Btu/lbm, extract 143 in the HP turbine, *reheat* by 202 and extract
another 139 + 380 through IP and LP, reject the rest in the condenser,
repeat — 1109 lbm of it per second.

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| two-property fits $(\rho,h) \to p,T,s$ | `superheatedSteam`, `reheatSteam` | `model.SteamTables` |
| one-property saturation fits | `drumSaturation`, `deaeratorSaturation` | `model.SteamTables` |
| isentropic reference $h_i$ | inside `hpTurbineExhaust`, `crossoverSteam` | `model.SteamTables` |
| quality at LP exhaust | `condenser(p, qy)` | `model.SteamTables` |
:::

Next: [Steam tables and polynomial fits](@basics/steam-tables) — how a
1977 computer turned the steam tables into arithmetic, and what those
mysterious coefficients in the code really are.
