---
description: The sixteen water/steam property fits cataloged — signatures, thesis subroutines, operating regions, and the two exhaust fits that carry the isentropic-efficiency pattern.
sourceFile: src/+model/SteamTables.m
---

# SteamTables.m

Sixteen static methods, no state, no loops — just the
[polynomial fits](@basics/steam-tables) that stand in for the steam
tables, one per operating region. This page is the catalog; the
[concepts page](@basics/steam-tables) explains why they exist and what
their limits are.

::: why
When a simulation goes physically wrong — an impossible temperature, a
negative density — the property fits are where to look first, because
they are the only functions that will happily return nonsense outside
their fitted regions. Knowing which fit serves which region turns that
hunt from archaeology into a lookup.
:::

## The catalog

**Saturated regions** — one input fixes everything
([the tightened two-property rule](@basics/thermo-properties)):

| Method | Thesis | Serves | In → out |
|---|---|---|---|
| `drumSaturation` | DRSTAT | [drum](@plant/waterwalls-drum), ≈2800 psia | `rs` → `rw, hw, hs, ps, Ts` |
| `deaeratorSaturation` | DESTAT | [deaerator](@plant/feedwater-train), ≈60 psia | `rs` → `rw, hw, hs, ps, ts` |
| `heaterSteamSat` / `heaterWaterSat` | LSSTAT / LWSTAT | extraction heaters | `p` → sat. steam / water props |

**Superheated steam** — two inputs, the model's stored pair:

| Method | Thesis | Serves | In → out |
|---|---|---|---|
| `superheatedSteam` | SHSTAT | [superheaters](@plant/superheaters), steam chest | `(r, h)` → `p, T, s` |
| `reheatSteam` | RHSTAT | [reheater](@plant/reheater), lower p | `(r, h)` → `p, T, s` |

**Compressed liquid** — feedwater-side properties:

| Method | Thesis | Serves |
|---|---|---|
| `feedwater` | FWSTAT | [economizer / HP-heater water](@plant/feedwater-train) |
| `condensateWater` | CWSTAT | condensate string |
| `condensatePumpOutlet` / `feedpumpOutlet` | CPSTAT / FPSTAT | pump discharge states |
| `recircWater` | RWSTAT | [downcomer water](@plant/waterwalls-drum) |

**Expansion endpoints** — the
[isentropic-efficiency pattern](@basics/turbines):

| Method | Thesis | Serves |
|---|---|---|
| `hpTurbineExhaust` | HPSTAT | HP exhaust / cold reheat |
| `crossoverSteam` | CRSTAT | IP exhaust / [cross-over](@plant/turbine-train) |
| `condenser` | CNSTAT | [LP exhaust at fixed quality](@plant/condenser) |

**Spray mixers** — post-injection states:

| Method | Thesis | Serves |
|---|---|---|
| `superheatSprayMix` | SYSTAT | [desuperheater](@plant/superheaters) |
| `reheatSprayMix` | RYSTAT | [reheat spray](@plant/reheater) |

## Reading a fit

Every method is the same shape — powers of the inputs, literal
coefficients, no branching:

```matlab
function [p, T, s] = superheatedSteam(r, h)
    % Superheater steam p,T,s from density and enthalpy.  (thesis SHSTAT)
    ...
end
```

The coefficients are *local to the method*
([by policy](@code/parameters)): they are the fit, not plant
parameters. The comment names the thesis subroutine, which is the
audit trail back to the printed listing.

## The one with a story

`crossoverSteam` carries the repository's most instructive comment —
the anchoring choice (`ho = h1 - ef*(h1 - hi)`, inlet-anchored) that an
ambiguous scan once flipped, caught because the wrong reading put the
cross-over below saturation and broke the feed pump torque balance.
The [full story](@basics/steam-tables) is prerequisite reading for
anyone tempted to "fix" a fit: **physics audits the math here, always.**

::: caution
The fits carry no range checks — outside their regions they extrapolate
silently ([the quiet failure mode](@basics/steam-tables)). If you
extend the model into new regimes (deeper part load, higher pressure),
spot-check the fits you rely on against real steam tables before
trusting the trajectories.
:::

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| all sixteen fits | `model.SteamTables` statics | `src/+model/SteamTables.m` |
| callers, steam side | `thermoStates` and friends | `model.PowerPlant` |
| the CRSTAT choice | `crossoverSteam` + comment | `src/+model/SteamTables.m` |
:::

Next: [Hydraulics.m](@code/hydraulics) — the four network solves and
the orifice law.
