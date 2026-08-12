---
description: The 2×2 saturated-vessel inversion behind the drum and deaerator states, and the small fit that splits the deaerator's steam supply.
sourceFile: src/+model/VesselDynamics.m
---

# VesselDynamics.m

Two methods for the two [saturated vessels](@plant/waterwalls-drum).
The first is the mathematical heart of the water side: the joint solve
that turns net mass and energy imbalances into the paired state
derivatives. The second is a supporting fit for the
[deaerator's](@plant/feedwater-train) steam supply.

::: why
`saturatedVessel` is the model's densest ten lines of mathematics —
the one place where the state derivatives are not read directly off a
balance but *solved for*. Understanding why it must exist (phase
change inside the boundary) is understanding drum dynamics; the rest
is linear algebra.
:::

## The joint solve

```matlab
[f1, f2] = saturatedVessel(kv, vw, rs, rw, hw, hs, ...
                           k2, k3, k5, k6, k7, k9, k10, zm, ze)
```

Inputs: the vessel's total volume `kv`, its two states (water volume
`vw`, steam density `rs`), the current saturation properties (from the
vessel's [one-input fit](@code/steam-tables)), the *slopes* of those
saturation fits (`k2…k10` — the same polynomial coefficients,
differentiated), and the net mass and energy imbalances `zm`, `ze`
(`z206`/`z209` for the drum). Outputs: the two state derivatives.

The mathematics, compactly: total stored mass and energy are functions
of the two states,

$$M(v_w, \rho_s), \qquad E(v_w, \rho_s)$$

— because *every* phase property is chained to $\rho_s$ through
saturation. Conservation demands $\dot M = z_m$ and $\dot E = z_e$;
the chain rule turns that into a 2×2 linear system in
$(\dot v_w, \dot \rho_s)$ whose coefficients are the fit slopes:

$$
\begin{pmatrix}
\partial M/\partial v_w & \partial M/\partial \rho_s\\[2pt]
\partial E/\partial v_w & \partial E/\partial \rho_s
\end{pmatrix}
\begin{pmatrix}\dot v_w\\[2pt] \dot \rho_s\end{pmatrix}
=
\begin{pmatrix}z_m\\[2pt] z_e\end{pmatrix}
$$

`saturatedVessel` builds those four partials and inverts by hand
(Cramer's rule — it is only 2×2). Flashing and condensation never
appear explicitly: they *are* the off-diagonal coupling. That is why
[shrink and swell](@plant/waterwalls-drum) emerges mechanistically
rather than being modeled as a special effect.

One function, both vessels — the drum calls it with drum fits and
`z206`/`z209`, the deaerator with its own fits and `z226`/`z229`:

```matlab
[sig.f1dr, sig.f2dr] = ... saturatedVessel(P.kvdr, s.vdrw, s.rdrs, ...);
[sig.f1de, sig.f2de] = ... saturatedVessel(P.kvde, s.vdew, s.rdes, ...);
```

## The deaerator's steam diet

```matlab
[wderp, wdewh, wdebd, hderp, hdewh] = deaeratorSteam(wdrs, whp)  % thesis DESTMR
```

The [deaerator](@plant/feedwater-train) heats itself with a blend of
steam sources — extraction steam, waterwall-header vents, blowdown
flash — and this fit apportions them from two load indicators (drum
steam flow and HP flow). Its outputs are the `w·h` terms of the
deaerator's energy imbalance `z229`. A workhorse fit, no drama —
except that its flows also set the drum's blowdown
(`wdrbd = 2·wdebd`), one of those quiet cross-couplings the
[sig bus](@code/conventions) makes traceable.

::: caution
The 2×2 inversion divides by the system's determinant. Physically the
determinant stays comfortably nonzero across the vessels' operating
ranges — but it is fit-based, so the
[extrapolation warning](@code/steam-tables) applies with interest:
drive a vessel far off its fitted saturation range and the solve's
conditioning, not just its accuracy, degrades.
:::

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| the joint solve | `saturatedVessel(...)` | `src/+model/VesselDynamics.m` |
| drum / deaerator calls | `vesselBalances` | `model.PowerPlant` |
| imbalances | `z206/z209`, `z226/z229` | `PowerPlant.vesselBalances` |
| consumed by | `xdot(4,5)`, `xdot(19,20)` | `model.PowerPlant` |
:::

Next: [PowerPlant.m](@code/power-plant) — the class that assembles
everything on the physical side.
