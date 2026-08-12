---
description: Extraction fits, the induction-motor torque law and the feed pump turbine — five methods serving the rotating world.
sourceFile: src/+model/Turbomachinery.m
---

# Turbomachinery.m

Five static methods, three jobs: tap steam out of the turbines
(extraction fits), turn grid electricity into shaft torque (the
induction motor), and turn extraction steam into feed pump torque (the
FP turbine). The physics is on the
[turbines](@basics/turbines) and
[rotating machinery](@basics/rotating-machinery) pages.

::: why
This file is the plant's mechanical–electrical frontier: every torque
in every [speed-state balance](@basics/rotating-machinery) originates
here, and both electrical emergency tests (5 and 6) are exercises of
one method — `inductionMotor`.
:::

## The extraction fits

```matlab
[waux, wh] = hpExtraction(w)                       % thesis HPEXT
[w2x, w3x, h2x, p2x, p3x] = ipExtraction(w, p1, po, h1, ho)   % IPEXT
[w1lhs, w2lhs, wdex, wlhst, ...] = lpExtraction(w, pcro, pcn, hcro, hlpo)  % LPEXT
```

Each cylinder's taps are curve fits on its through-flow — more steam,
proportionally more extraction — with interstage pressures and
enthalpies interpolated between the cylinder's endpoints. The outputs
feed the [flow ledger](@plant/turbine-train) (`whpo`, `wipo`, `wlpo`)
and the heater balances of the
[feedwater train](@plant/feedwater-train). Note the asymmetry of
information: HP extraction needs only the flow; LP extraction needs
both endpoint states because its taps span the whole expansion into
vacuum.

## The induction motor

```matlab
[tq1, mw1] = inductionMotor(nelec, velec, knm, n, km, smax)
```

One method, four machines — recirculation pump, condensate pump, FD
and ID fans — differing only in their constants (`knm` pole-pair
factor, `km` torque scale, `smax` slip cap). Inside is the
[operating-region law](@basics/rotating-machinery): torque ∝ V² × slip,
clamped at the pull-out slip. The two grid inputs are the *scenario's*
levers: Test 5 steps `velec`, Test 6 ramps `nelec`, and this one
function converts each into four simultaneous torque disturbances.

## The feed pump turbine

```matlab
[tqfp1, mwfp1] = feedpumpTurbine(wft, hft1, nfp)   % thesis FPTURB
```

Steam flow times available enthalpy, divided by speed: torque. The
enthalpy input `hft1` has a detail worth knowing: the FP turbine
normally drinks [cross-over steam](@plant/turbine-train) (`hcro`), but
when the feed-pump-turbine supply switches source (high demand), the
model hands it main steam instead — a plumbing conditional in
`PowerPlant.machines`, not in this method. This torque is what
[audited the CRSTAT fix](@basics/steam-tables): wrong cross-over
enthalpy → wrong `tqfp1` → feed pump starves, visibly.

## Pattern: physics in, torque out

All five methods are pure fits/laws with no state and no side effects —
the [static-library pattern](@code/conventions) again. The *dynamics*
they cause live entirely in the speed states' torque balances in
`PowerPlant`; this file only ever answers "what torque/flow, right
now?"

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| the five methods | `model.Turbomachinery` statics | `src/+model/Turbomachinery.m` |
| motor constants per machine | `knrpm/krpm`, `kncpm/kcpm`, `knfdm/kfdm`, `knidm/kidm` | `model.Parameters` |
| torque consumers | `xdot(1, 6, 17, 21, 22)` | `model.PowerPlant` |
| FP steam-source switch | `hft1` conditional | `PowerPlant.machines` |
:::

Next: [HeatTransfer.m](@code/heat-transfer) — the furnace balance and
the convective chain.
