---
description: Closing the cycle below one psia — why the vacuum is worth a third of the plant's output, how the model fits condenser pressure, and where the rejected heat goes.
---

# Condenser

Below the LP (low pressure) turbine hangs a vessel doing the least
glamorous job in the plant: turning exhaust steam back into water
against cooling-water tubes. It is also, by a wide margin, the largest
heat flow on site — bigger than the fuel's useful share — and the
*pressure* it maintains is worth roughly a third of the plant's output.

::: why
The [enthalpy ladder](@basics/thermo-properties) only reaches down to
≈1000 Btu/lbm because the condenser holds the LP exhaust below 1 psia.
Let condenser pressure rise to atmospheric and the LP cylinder's
≈380 Btu/lbm drop shrinks toward 250 — over 100 MW gone, same fuel.
Vacuum is not a refinement; it is where the [pressure span's
3000:1 ratio](@basics/thermo-properties) gets its bottom end.
:::

## Why condensing creates vacuum

Seal a vessel, fill it with steam, cool it: the steam collapses into
water at 1/20,000th the volume, and the pressure falls until it reaches
the *saturation pressure of the cooling surface's temperature* —
around 1 psia for a condenser fed with typical cooling water. The
turbine exhausts into that near-vacuum, so the expansion continues far
below atmospheric. Keeping air leaks out (air does not condense — it
accumulates and blankets the tubes) is a real plant's eternal chore,
assumed perfect in the model.

## The model's condenser: an algebraic boundary

The condenser holds no state. The model computes its pressure from a
quadratic fit on cross-over pressure — effectively on load, since
[stage pressures follow flows](@basics/turbines) — and fixes the LP
exhaust quality at the thesis' design value:

```matlab
sig.pcn = P.k0pcn + P.k1pcn*sig.pcro + P.k2pcn*sig.pcro*sig.pcro;
sig.qylpo = P.kqylpo;    % LP exhaust quality: 0.926, constant
[sig.hlpo, sig.rlpo, ...] = model.SteamTables.condenser(sig.pcn, sig.qylpo);
```

At full load that gives ≈0.9 psia and an exhaust enthalpy near
1000 Btu/lbm — 7.4% of the steam arriving as water droplets (why LP
blading erodes, and why [reheat exists](@plant/reheater)). The
condensed water — the **hotwell** — is where the
[condensate pumps](@plant/feedwater-train) begin the journey back to
the drum; its temperature is saturation at `pcn`, ≈100 °F: the cycle's
cold reservoir.

Fixing quality and fitting pressure to load is a deliberate boundary
choice: the thesis' emergency scenarios never disturb the cooling-water
side, so the condenser can be a terminus rather than a component —
the same rank as the [infinite bus](@basics/generator-grid) on the
electrical side and ambient air on the gas side.

## The heat that leaves

At 100% load the ledger closes roughly as: 1.46×10⁶ Btu/s of fuel heat
in; ≈1.2×10⁶ absorbed by the steam; ≈0.57×10⁶ out as electricity; and
on the order of 0.6×10⁶ Btu/s rejected here to the cooling water —
warm water to a river or cooling tower, the thermodynamic tax the
second law charges for turning heat into work. No design cleverness
avoids it; the [extraction strategy](@basics/turbines) exists precisely
to shrink it.

::: metrics The condenser at 100% load
| Quantity | Value |
|---|---|
| Pressure `pcn` | ≈0.9 psia |
| LP exhaust quality | 0.926 (fixed) |
| Exhaust enthalpy `hlpo` | ≈1000 Btu/lbm |
| Hotwell temperature | ≈100 °F (saturation at `pcn`) |
| Heat rejected | ≈0.6×10⁶ Btu/s |
:::

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| pressure fit | `pcn = k0pcn + k1pcn·pcro + k2pcn·pcro²` | `model.PowerPlant` |
| exhaust state | `condenser(pcn, qylpo)` (thesis CNSTAT) | `model.SteamTables` |
| fixed quality | `kqylpo = 0.92632` | `model.Parameters` |
| condensate side | `condensate(pcn, …)` network | `model.Hydraulics` |
:::

Next: [The feedwater train](@plant/feedwater-train) — pumps and heaters
carrying hotwell water back up to 2778 psia and 478 Btu/lbm.
