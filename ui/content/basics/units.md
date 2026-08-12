---
description: The English engineering unit system the model runs in — pound-mass vs pound-force, the constant g_c, Rankine temperatures, Btu and psia — and the real bug a units subtlety once caused.
---

# Units and the English engineering system

Every quantity in the model — every constant, every state, every equation —
is written in **English engineering units**: pounds, feet, seconds, °F and
Btu (British thermal units). That is the system the 1977 thesis, and the US
power industry it came from, worked in. This page builds the small set of
units you will see everywhere, and ends with the one genuine trap in the
system — a trap that produced a real bug in this model's history.

::: why
Getting units right is not bookkeeping. In this unit system force and mass
units are related by a *numerical constant*, not by 1, so an equation can
be algebraically correct and still be wrong by a factor of 32.174. The
model's turbine–generator inertia had exactly that bug — the plant
"worked" at steady load and fell apart in one specific emergency test.
:::

## Mass, force and $g_c$

The system uses the pound twice, for two different things:

::: definition lbm — pound-mass
The unit of **mass**. One lbm (pound-mass) is the mass of the standard
avoirdupois pound. Water density, steam flow rates and stored masses in
the model are all lbm-based: flows in lbm/s, densities in lbm/ft³.
:::

::: definition lbf — pound-force
The unit of **force**. One lbf (pound-force) is the *weight* of one lbm in
standard gravity. Pressures (lbf/in², i.e. psia) and torques (lbf·ft) are
lbf-based.
:::

Newton's second law relates force to mass times acceleration. With mass in
lbm, acceleration in ft/s² and force in lbf, the law needs a conversion
constant:

::: equation Newton's second law in English engineering units
$$F = \frac{m\,a}{\gc},
\qquad
\gc = 32.174\ \frac{\mathrm{lbm}\cdot\mathrm{ft}}{\mathrm{lbf}\cdot\mathrm{s}^2}$$
:::

The value 32.174 is numerically equal to standard gravity in ft/s² — by
construction, so that 1 lbm *weighs* 1 lbf. The price is that $\gc$ must
appear in every equation that mixes mass-based and force-based quantities.
In SI (the metric system) $\gc$ is simply 1 and invisible; here it is not,
and forgetting it (or applying it twice) changes answers by a factor of
32.174.

## Temperature: °F and °R

Temperatures are measured in degrees Fahrenheit (°F), but *thermodynamic*
equations need an absolute scale — one whose zero is absolute zero.
That scale is **Rankine**:

::: equation Rankine from Fahrenheit
$$T\,[\degR] = T\,[\degF] + 459.67$$
:::

Rankine is to Fahrenheit what Kelvin is to Celsius: same step size, shifted
zero. The model stores every temperature in °R and the difference matters
whenever temperatures are multiplied or raised to powers — the furnace
radiation law goes as $T^4$, and $(1000\,\degF)^4$ computed by mistake
instead of $(1459.67\,\degR)^4$ is off by a factor of 4.5.

## Energy and power: Btu

::: definition Btu — British thermal unit
The energy needed to raise one lbm of water by 1 °F: $1\ \mathrm{Btu}
\approx 1055\ \mathrm{J}$. Specific enthalpies are Btu/lbm and heat flows
are Btu/s throughout the model.
:::

One conversion is worth memorizing, because it connects the boiler's
thermal world to the generator's electrical world:

::: equation Thermal to electrical power
$$1\ \mathrm{MW} = 947.8\ \mathrm{Btu/s}
\qquad\text{so}\qquad
600\ \mathrm{MW} \approx 5.7\times10^{5}\ \mathrm{Btu/s}$$
:::

At full load this plant burns fuel at about $1.46\times10^{6}$ Btu/s to
deliver 600 MW of electricity — the ratio between those two numbers is the
whole story of a power plant's efficiency, and later pages account for
where every Btu goes.

## Pressure: psia

::: definition psia — pounds per square inch, absolute
Pressure in lbf/in², measured from vacuum (that is the "absolute"; gauge
pressure, psig, measures from atmospheric instead). The model is entirely
absolute: atmospheric pressure is 14.7 psia, main steam leaves the boiler
at 2415 psia, and the condenser runs below 1 psia.
:::

The pressure span inside this single machine — from 2415 psia at the
throttle to under 1 psia at the condenser — is a ratio of more than
3000:1, and it is what makes steam expansion worth so much work.

## The trap: rotational inertia and $WR^2$

Here is where $\gc$ bites. A rotor's equation of motion is

::: equation Rotor dynamics
$$J\,\frac{d\omega}{dt} = \sum T$$
:::

with torque $T$ in lbf·ft. For the law to be consistent, the inertia $J$
must be in **slug·ft²** (a slug is the mass that accelerates at 1 ft/s²
under 1 lbf — equal to 32.174 lbm). But manufacturers traditionally quote
rotating inertia as **$WR^2$ in lbm·ft²** — weight times radius of
gyration squared. The two differ by exactly $\gc$:

::: equation Vendor inertia to dynamic inertia
$$J\ [\mathrm{slug}\cdot\mathrm{ft}^2]
= \frac{WR^2\ [\mathrm{lbm}\cdot\mathrm{ft}^2]}{\gc}$$
:::

The thesis data deck lists the turbine–generator inertia as
`KJTRE = 625000`. Read as slug·ft² it implies a machine with an inertia
constant of about 88 seconds — an order of magnitude beyond any real
turbine-generator. Read as vendor-style $WR^2$ and divided by $\gc$, it
gives about 2.7 s — physically right, and the only reading under which the
thesis' own frequency-drop test survives. The model applies that
correction in code:

```matlab
kjtre = 625000/32.174; % units correction, see docs/model.md
```

::: caution
The correction is deliberate and applied exactly once, in the generated
`Parameters.m`. The other rotor inertias in the deck (feed pump, fans,
condensate and recirculation pumps) validate as-listed against the thesis'
motor slow-down tests, so only `kjtre` is corrected.
:::

## What you should take away

- Mass in lbm, force in lbf, and $\gc = 32.174$ whenever they meet.
- Temperatures in °R for anything thermodynamic; °F is display only.
- Energy in Btu, flows in lbm/s, enthalpy in Btu/lbm, pressure in psia.
- When a data sheet says "inertia", ask: slug·ft² or $WR^2$ in lbm·ft²?

Next: [States, systems and ODEs](@basics/state-variables) — what it means
for this plant to be a "47th-order" system.
