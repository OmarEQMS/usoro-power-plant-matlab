---
description: Control volumes, conservation of mass and energy, and how "accumulation = in − out" generates almost every physical state equation in the model.
---

# Mass and energy balances

Where do the rows of $f(t,x)$ come from? For the physical half of the
model, almost every one is an instance of a single idea applied over and
over: draw a boundary around a piece of the plant, and require that
whatever it stores can only change by what crosses the boundary. This
page builds that idea — the **balance** — and then shows it verbatim in
the model's code.

::: why
Twenty of the model's 23 physical states are stored masses and energies
(densities, enthalpies, volumes, a metal temperature). Once you can write
"accumulation equals in minus out" fluently, you can *derive* most of
`PowerPlant.m` yourself rather than memorize it.
:::

## Control volumes

::: definition Control volume
A **control volume** is an imaginary boundary drawn around a region of
the plant — a heat exchanger, a drum, a length of pipe. We track what is
stored inside it and what flows across its boundary. The art of modeling
is choosing boundaries so that what crosses them is measurable and what
happens inside them is simple.
:::

The model slices the plant into a few dozen control volumes: each heat
exchanger is one, the drum is one, the deaerator is one, each stretch of
steam path with meaningful storage is one. Everything inside a volume is
treated as **lumped** — one representative density, one enthalpy, one
temperature for the whole region, instead of a value at every point in
space. That is the trade the model makes everywhere: spatial detail is
given up so that each region contributes just one or two ODEs
(ordinary differential equations).

## The mass balance

Mass is neither created nor destroyed, so for any control volume:

::: equation Conservation of mass
$$\frac{dM}{dt} \;=\; \sum w_{\mathrm{in}} \;-\; \sum w_{\mathrm{out}}$$
:::

with $M$ the stored mass (lbm) and $w$ the mass flows (lbm/s) crossing
the boundary. For a *rigid* volume $V$ (a steel vessel does not stretch),
$M = \rho V$ with $V$ constant, so tracking mass is the same as tracking
density:

::: equation Mass balance in density form
$$\frac{d\rho}{dt} \;=\; \frac{\sum w_{\mathrm{in}} - \sum w_{\mathrm{out}}}{V}$$
:::

That is already a model equation. Here is the reheater's steam-mass
balance — state 13, exactly as `PowerPlant.m` computes it:

```matlab
xdot(13) = (sig.wrh1 - sig.wiv)/P.kvrh;
```

Read it: `wrh1` is the flow entering the reheater (lbm/s), `wiv` the flow
leaving through the intercept valve, `kvrh` the reheater's fill volume
(ft³), and state 13 is the reheater outlet steam density `rrho`
(lbm/ft³). The line *is* the equation above, nothing more.

## The energy balance

Energy is also conserved, but it crosses boundaries in more disguises:
carried by flowing mass, conducted as heat, extracted as work. For the
flow term there is a beautiful simplification: a stream of mass $w$
carries internal energy *and* does "pushing" work on the volume as it
enters. Both effects together equal $w \cdot h$, where $h$ is the
stream's **specific enthalpy** — this is the reason enthalpy, not
internal energy, is the working currency of every flow system (the next
page makes $h$ precise). The balance reads:

::: equation Conservation of energy for a flow volume
$$\frac{dE}{dt} \;=\; \sum w_{\mathrm{in}}\,h_{\mathrm{in}}
\;-\; \sum w_{\mathrm{out}}\,h_{\mathrm{out}}
\;+\; Q \;-\; W$$
:::

with $Q$ the heat added across the boundary (Btu/s — from the flue gas,
say) and $W$ any work extracted (zero for heat exchangers; nonzero for
turbines). The model tracks the stored energy through the outlet specific
enthalpy $h_{\mathrm{out}}$ and an effective stored mass $m_e$, giving
the working form its state equations use:

::: equation Energy balance, enthalpy form
$$\frac{dh_{\mathrm{out}}}{dt} \;=\;
\frac{\sum w_{\mathrm{in}} h_{\mathrm{in}}
- \sum w_{\mathrm{out}} h_{\mathrm{out}} + Q}{m_e}$$
:::

And again the code is the equation. The reheater's energy balance —
state 14, the outlet enthalpy `hrho`:

```matlab
xdot(14) = (sig.wrh1*sig.hrh1 - sig.wiv*s.hrho + sig.qrh)/sig.mrhe;
```

Flow in times its enthalpy, minus flow out times the outlet enthalpy,
plus the heat absorbed from the flue gas (`qrh`), divided by the
effective mass `mrhe`.

::: definition Effective mass
The **effective mass** $m_e$ lumps the stored steam *and* the metal of
the exchanger walls into one thermal storage: the steel heats and cools
with the steam and holds a great deal of energy (the reheater carries
944,000 lbm of metal). Treating fluid + metal as one store is another
deliberate lumping — it costs some transient fidelity and saves one
state per exchanger.
:::

::: caution
Two bookkeeping details bite anyone rederiving these equations. First,
*outflow carries the stored enthalpy*: the $w_{\mathrm{out}}
h_{\mathrm{out}}$ term uses the state itself, which is what makes the
equation self-regulating. Second, watch the mixed units: flows in lbm/s,
enthalpies in Btu/lbm, heat in Btu/s — consistent here, but any SI
ingredient sneaked into a term breaks everything silently.
:::

## Steady state is a balance, literally

Set the accumulation terms to zero and the balances say: at equilibrium,
mass in equals mass out, and energy in equals energy out, volume by
volume. This is why finding an operating point (the trimming from the
[previous page](@basics/state-variables)) is really solving a giant
simultaneous in-equals-out problem across every control volume at once —
and why one component absorbing slightly too little heat forces the
whole chain, back to the fuel valve, to shift.

## Where the idea shows up beyond mass and energy

The same "stored quantity changes by what crosses the boundary" template
covers the model's remaining physical states:

- **Momentum:** a rotor stores angular momentum; torques are its
  "flows". That is the $J\,\dot\omega = \sum T$ from the
  [units page](@basics/units) — six of the plant's states are shaft
  speeds governed by torque balances.
- **Saturated vessels:** the drum and deaerator store a boiling
  liquid–vapor mixture; their balances need care because mass and energy
  shift *between phases* inside the volume. They get their own treatment
  on the [drum page](@plant/waterwalls-drum).
- **Controller integrators:** an integrator "stores" accumulated error;
  its inflow is the error signal. Same shape, no physics.

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| mass balances (density states) | `xdot(5,8,10,12,13,15,20)` | `model.PowerPlant`, physical derivatives |
| energy balances (enthalpy states) | `xdot(2,3,9,11,14,18)` | `model.PowerPlant`, physical derivatives |
| effective masses $m_e$ | `sig.mrhe`, `sig.msse`, … | `PowerPlant.effectiveMasses` |
| heat inputs $Q$ | `sig.qrh`, `sig.qss`, … | `model.HeatTransfer` |
:::

Next: [Thermodynamic properties of water](@basics/thermo-properties) —
what enthalpy actually is, and how pressure, temperature, density and
enthalpy tie together for steam.
