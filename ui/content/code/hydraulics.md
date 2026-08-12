---
description: One orifice law and four closed-form network solves — the file that answers "given these pressures and speeds, what flows?"
sourceFile: src/+model/Hydraulics.m
---

# Hydraulics.m

Five static methods answer every "how much flows?" question in the
model: one primitive (the orifice law) and four **network solves**, one
per major loop. The physics is the
[flow](@basics/fluid-flow) and [machine-curve](@basics/pumps-fans)
pages; this page is how the file organizes it.

::: why
`Hydraulics` is where the model's *algebraic* character is most
visible: every flow, every intermediate pressure, every pump efficiency
is computed fresh and in closed form at each call — no iteration, no
solver, no tolerance. That design decision (reduce every circuit to a
quadratic by hand) is what the file's structure expresses.
:::

## The primitive

```matlab
w = orificeFlow(r, pd, kf)     % thesis SHFLOW
```

The [sign-preserving square-root law](@basics/fluid-flow) — used
directly in `PowerPlant` for the steam-path restrictions (drum →
primary superheater, between superheater stages) and implicitly, as
the building block, inside every network below.

## The four networks

Each function bundles one loop's machine curves, valve/vane areas and
frictions, and returns the flow *plus every intermediate the rest of
the model needs* — pressures for other components, efficiencies for
the [torque balances](@basics/rotating-machinery):

| Method | Thesis | Loop | Key inputs → outputs |
|---|---|---|---|
| `feedwater` | FWFLOW | [deaerator → drum](@plant/feedwater-train) | `afv, nfp, pdes, pdrs` → `wfp, wfw, …, pfvd, efp` |
| `condensate` | CWFLOW | [hotwell → deaerator](@plant/feedwater-train) | `pcn, ncp, adv` → `wcw, wcp, …, ecp` |
| `recirculation` | RWFLOW | [drum → waterwalls](@plant/waterwalls-drum) | `nrp, pdrs` → `wrw, wrp, wwwo, …, erp` |
| `airGas` | ARFLOW | [the whole gas path](@plant/air-gas-path) | `knfd, knid, nfd, nid, wgr, wfl, avf, avi` → `war, wwwg, …, pfn, efd, eid` |

The signatures tell the coupling story at a glance: each solve takes
**states** (shaft speeds), **actuator areas** (the control system's
outputs) and **boundary pressures** (other components' conditions), and
returns the loop's operating point. Change any input and the whole
loop's flows shift together — which is exactly the physics.

## Inside a solve

All four follow the same recipe, visible in `feedwater`:

1. local fit coefficients up top (pump curves `k1fp…k6fp`, local
   frictions) — [subroutine-local by policy](@code/parameters);
2. algebraic reduction: series frictions summed, machine curves and
   static heads combined into one quadratic in the unknown flow;
3. the closed-form root, then back-substitution for every intermediate
   pressure and the machine efficiency.

No loops, no conditionals beyond flow-direction guards — each solve is
a straight-line computation, cheap enough to run four times per RK4
step without thought.

::: caution
The closed forms are *manual* derivations from the thesis — the hardest
code in the model to audit, because a slip in the algebra produces
plausible flows that are simply wrong. The `airGas` network is the
open investigation's prime suspect for exactly this reason: at the
thesis' own 100% state it delivers ≈4% less air than the thesis'
published value. Treat these functions as verified-in-use, not
verified-line-by-line — yet.
:::

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| the five methods | `model.Hydraulics` statics | `src/+model/Hydraulics.m` |
| callers | `steamPathAndTurbines`, `waterSide`, `airGasSide` | `model.PowerPlant` |
| network outputs → torques | `efp, ecp, erp, efd, eid` | `PowerPlant` speed states |
:::

Next: [Turbomachinery.m](@code/turbomachinery) — extractions, motors
and the feed pump turbine.
