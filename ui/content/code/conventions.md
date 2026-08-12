---
description: The naming scheme that makes 300 constants and 47 states readable — thesis symbols, the k-families, loop prefixes, and the sig bus contract.
---

# Naming and conventions

This code base keeps the thesis' 1977 FORTRAN names — `kjtre`, `qwwgm`,
`cxggd` — instead of renaming to modern taste. That is a deliberate
trade: the names look cryptic for a day and then become a superpower,
because every identifier cross-references directly against the thesis'
equations and every variable in a 47-year-old listing. This page is the
decoder.

::: why
The naming scheme is systematic enough that, once learned, you can
usually *derive* what a variable means without looking it up — and this
site's tooltips (hover any identifier in a code span) fill the gaps.
:::

## First letter = quantity

| Prefix | Quantity | Unit | Examples |
|---|---|---|---|
| `w` | mass flow | lbm/s | `wfl`, `whp`, `wfw` |
| `h` | specific enthalpy | Btu/lbm | `hsso`, `hrho`, `heco` |
| `r` | density | lbm/ft³ | `rdrs`, `rsco`, `rcro` |
| `t` | temperature | °R | `trho`, `twwm`, `tfn1` |
| `p` | pressure | psia | `psso`, `pdrs`, `pfn` |
| `q` | heat rate | Btu/s | `qrh`, `qwwgm`, `qec` |
| `n` | shaft speed | rad/s | `ntr`, `nfp`, `nid` |
| `v` | volume | ft³ | `vdrw`, `vdew` |
| `x` | level / position | in, rad | `xdrw`, `xgg` |
| `mw` | power | see [turbines](@basics/turbines) | `mwtro`, `mwgn` |
| `a` | actuator area | 0–1 | `acv`, `afv`, `avi` |
| `e` | machine efficiency | 0–1 | `efp`, `ecp`, `eid` |

The tail names the component: `sso` = secondary superheater outlet,
`drs` = drum steam, `cro` = cross-over, `fpo` = feed pump outlet. Read
`hsso` as *h·sso*: enthalpy, secondary superheater outlet.

## Constants: the k-families

Everything in `Parameters` starts with `k`, and the second letter
sorts it:

| Family | Meaning | Examples |
|---|---|---|
| `kj*` | rotor inertia (J) | `kjtre`, `kjfd` |
| `kv*` | fill volume | `kvrh`, `kvdr` |
| `kf*` | friction coefficient | `kfps`, `kfec` |
| `ku*` | heat-transfer coefficient | `kupsgm`, `kuwwmw` |
| `km*m` / `ks*m` | metal mass / specific heat | `kmrhm`, `kswwm` |
| `kc*` | controller gain | `kc1rh`, `kcvreg` |
| `ktc*` | controller time constant | `ktc1md`, `ktc2fl` |
| `kn*` | numeric literal from the deck | `kn2`, `kn144`, `knp087` |
| `k1x…/k2x…` | fit coefficients, numbered | `k1trh`, `k2xgg` |

Ranges come as `l/u` pairs (`kwfll`/`kwflu` = fuel-flow transducer
lower/upper), set points often as a bare name (`kpfvd` = 30 psi).

## Control signals: `c` + block number + loop

Control-system intermediates are `c<N><loop>`: `c3md` is block 3 of
the boiler-**m**aster **d**emand chain, `c5rh` block 5 of the
**r**e**h**eat loop. The numbers follow the thesis' block diagrams, so
`ControlSystem.derivatives` reads against Chapter IV figure by figure.
A trailing `d` marks a *demand* the plant actually consumes (`cfld`,
`cxggd` — the [actuator-lag states](@basics/control-basics)).

## The `sig` bus contract

`PowerPlant.evaluate` accumulates every intermediate quantity in one
struct, under its thesis name:

```matlab
[xdot, sig] = plant.evaluate(s, u, g);
sig.whp      % HP steam flow, this instant
sig.qwwgm    % waterwall radiant absorption, this instant
```

Three rules make the bus dependable: **write once** (each signal is
assigned in exactly one place, in evaluation order), **no state** (the
bus is rebuilt from scratch every call — `f(t,x)` stays
[pure](@basics/state-variables)), and **everyone reads it** (the
control system's measurements and the logger's columns are just bus
look-ups; there are no private side channels).

## Class conventions

- Package `+model`; classes PascalCase, methods camelCase; the thesis
  names live *inside* method bodies and the `sig`/`Parameters` fields.
- **Value classes** for data (`Parameters`, `LoadProfile`,
  `GridProfile`) — copy freely for
  [parameter studies](@code/parameters); **handle classes** for the
  machines (`PowerPlant`, `ControlSystem`, `Simulator`).
- Static-method classes (`SteamTables`, `Hydraulics`, …) are stateless
  function libraries — thesis subroutines with a namespace.
- Code floor is R2019b (`arguments` validation blocks in five files).

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| every identifier's tooltip | hover any code span on this site | `ui/pipeline/identifiers.ts` |
| the bus in action | `PowerPlant.evaluate` | `src/+model/PowerPlant.m` |
| block-numbered control code | `ControlSystem.derivatives` | `src/+model/ControlSystem.m` |
:::

Next: [Parameters.m](@code/parameters) — the 306 numbers everything
else multiplies by.
