---
description: How steam expansion becomes shaft power — enthalpy drops, isentropic efficiency, extractions, and the three lines of code that compute 600 MW.
---

# Turbines and expansion work

Pumps and fans spend shaft power to raise pressure. Turbines are the
same machine run for profit: high-pressure steam expands through rows of
blading, and the enthalpy it gives up leaves through the shaft. In this
plant three turbine cylinders in series — HP, IP, LP (high,
intermediate, low pressure) — convert about 1100 lbm/s of steam into
600 MW. This page is the energy accounting that makes that number.

::: why
The turbine model is where the plant's purpose is computed — literally
three lines in `PowerPlant.m` that this page derives. It is also where
the isentropic-efficiency pattern lives, the pattern behind two of the
model's steam-table functions and one famous transcription bug.
:::

## Work = flow × enthalpy drop

Apply the [energy balance](@basics/mass-energy-balances) to a turbine as
a control volume at steady flow: no stored mass changing, negligible heat
loss, and now the work term $W$ matters. What comes out on the shaft is
exactly what the steam gives up:

::: equation Turbine shaft power
$$W \;=\; w\,\big(h_{\mathrm{in}} - h_{\mathrm{out}}\big)$$
:::

That is the whole principle. The engineering is in what sets
$h_{\mathrm{out}}$ — how *much* enthalpy the steam can be persuaded to
surrender before it leaves.

## The ideal, and the fraction of it you get

Expansion in a perfect (frictionless, adiabatic) turbine holds entropy
constant — that was the [preview](@basics/thermo-properties) — ending at
the isentropic enthalpy $h_i$ for the exhaust pressure. Real blading has
friction, leakage, moisture: it recovers a fixed *fraction* of the ideal
drop, called the *isentropic efficiency* $\eta$:

::: equation Isentropic efficiency
$$h_{\mathrm{out}} \;=\; h_{\mathrm{in}} \;-\; \eta\,\big(h_{\mathrm{in}} - h_i\big)$$
:::

This is the exact pattern of the model's exhaust-state fits — the HP
exhaust and the cross-over:

```matlab
ho = h1 - ef*(h1 - hi);     % hpTurbineExhaust and crossoverSteam
```

Anchor the formula at $h_1$ (the inlet), subtract the recoverable
fraction of the ideal drop. Anchoring it at $h_i$ instead — the reading
a smudged scan of the thesis briefly suggested — produces steam below
its own saturation temperature, and the
[steam-tables page](@basics/steam-tables) told the story of how physics
vetoed that reading.

## Three cylinders, three lines of code

The model computes each cylinder's power from its flow and enthalpy
drop, exactly as the shaft-power equation prescribes:

```matlab
sig.mwhp = sig.whp*(s.hsso - sig.hhpo)*P.kj;
sig.mwip = sig.wip*(s.hrho - sig.hcro)*P.kj*keip;
sig.mwlp = sig.wlp*(sig.hcro - sig.hlpo)*P.kj*kelp;
sig.mwtro = sig.mwhp + sig.mwip + sig.mwlp;
```

Read against the [enthalpy ladder](@basics/thermo-properties): HP expands
main steam (1460) to cold reheat (1317); IP expands hot reheat (1519) to
the cross-over (1380); LP expands the cross-over down into the condenser
(≈1000). Multiply each drop by its flow, and 600 MW appears. The factor
`P.kj` is $J = 778.17$ ft·lbf/Btu from the [units page](@basics/units):
power is kept in ft·lbf/s so that dividing by shaft speed gives torque
directly in lbf·ft — this `mwtro` is the driving side of the swing
equation. (`keip`, `kelp` apply the stage efficiency to the downstream
cylinders.)

Notice the flows shrink stage to stage: `whp` → `wip` → `wlp`. That is
not leakage — it is deliberate:

## Extractions

::: definition Extraction (bleed) steam
Partially expanded steam tapped from between turbine stages to heat
feedwater (and to drive the feed pump turbine). Extraction trades a
little turbine output for a larger boiler saving — feedwater arrives hot,
so less fuel re-heats it — and is why every large steam plant's
feedwater is heated in stages by its own turbines.
:::

The model taps steam at six points: HP exhaust and cross-over feed the
HP feedwater heaters and deaerator; LP stages feed the LP heaters; one
tap drives the feed pump turbine. Each extraction flow is a curve fit on
the local stage flow (thesis HPEXT, IPEXT, LPEXT — in
`model.Turbomachinery`), and each one reappears as a $w \cdot h$ term in
some heater's [energy balance](@basics/mass-energy-balances). Nothing is
lost: what leaves the turbine's ledger enters a heater's.

## Pressures follow flows

One more turbine fact the control system leans on: at turbine inlet
conditions, stage pressure is very nearly *proportional to flow* (with
choked nozzle rows, doubling flow doubles the pressure needed to drive
it). The model uses the cleanest case — the first stage:

```matlab
sig.p1st = P.k1p1st*sig.whp;
```

First-stage pressure is a perfect internal flow meter: measure `p1st`
and you know the steam flow without a flow element. The feedwater
control uses exactly this signal as its steam-flow measurement — a
classic plant practice the model reproduces faithfully.

## The governor's lever

Between the boiler and the HP turbine sit the **governor valves** — the
`wtv` valve law from the [flow page](@basics/fluid-flow). They are the
fastest actuator in the plant: steam flow (hence power, within seconds)
follows valve area immediately, while the boiler takes minutes to change
what it makes. Every load-following strategy is built on that speed
asymmetry, and the [control pages](@basics/control-practices) return
to it.

::: metrics The train at 100% load
| Quantity | Value |
|---|---|
| Main steam flow into HP | 1109 lbm/s |
| HP / IP / LP enthalpy drops | 143 / 139 / ≈380 Btu/lbm |
| Total shaft power | 600 MW |
| Cross-over conditions | ≈173 psia, ≈709 °F |
| LP exhaust quality | ≈93% |
:::

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| cylinder powers | `sig.mwhp`, `sig.mwip`, `sig.mwlp`, `sig.mwtro` | `model.PowerPlant` |
| exhaust states via $\eta$ | `hpTurbineExhaust`, `crossoverSteam` | `model.SteamTables` |
| extraction fits | thesis HPEXT / IPEXT / LPEXT | `model.Turbomachinery` |
| first-stage pressure | `sig.p1st = P.k1p1st*sig.whp` | `model.PowerPlant` |
| governor valve | `sig.wtv = P.kcv*sig.acv*sqrt(...)` | `model.PowerPlant` |
:::

Next: [Heat transfer](@basics/heat-transfer) — how the furnace's
1.5 million Btu/s find their way into the steam.
