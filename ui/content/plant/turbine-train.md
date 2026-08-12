---
description: The HP-IP-LP train as hardware — governor valves, steam chest, cross-over, extraction taps — and the flow bookkeeping that threads one steam stream through three machines.
---

# The turbine train

The [turbines page](@basics/turbines) built the physics: enthalpy drops,
isentropic efficiency, three lines of code worth 600 MW. This page walks
the *hardware* those lines describe — one shaft, three cylinders, and
the valves, chests and pipes between them — and the flow bookkeeping
that the model keeps at every station.

::: why
Two of the model's states live in the train's plumbing (the steam chest
and the cross-over pipe), and the train's flow ledger — what enters HP,
what leaves for heaters, what reaches the condenser — feeds every
feedwater-side balance. Reading this page, you can follow a pound of
steam through `PowerPlant.m` line by line.
:::

## Admission: throttle, governor valves, steam chest

Main steam meets the **governor valves** first — the plant's fastest
actuator (`wtv`, the [valve law](@basics/fluid-flow), area `acv` from
the [governor loop](@plant/loops-turbine)). They discharge into the
**steam chest** (state 12, `rsco`): a header volume ahead of the first
stage whose stored density is the model's memory of admission
transients — slam the valves and chest pressure, not turbine flow,
moves first. From the chest, the governing stage swallows flow by the
choked-nozzle law, and the first-stage pressure tap `p1st` reports it —
the [internal flow meter](@basics/turbines) the feedwater control
trusts.

## Through the cylinders

- **HP:** 1109 lbm/s in at 1460 Btu/lbm. On the way out, the ledger
  starts: an auxiliary tap (`whpaux`) and the first heater extraction
  (`w1hhs`) peel off, and what remains (`whpo`) heads back to the
  boiler as cold reheat: `wrh1 = whpo + wry` (plus any
  [reheat spray](@plant/reheater)).
- **IP:** re-energized steam (1519 Btu/lbm) enters past the intercept
  valve (`wiv` — wide open in operation; its job is slamming shut on
  overspeed). Out the far end: two more heater extractions (`w2hhs`,
  `w3hhs`) and the feed pump turbine's supply (`wipftx`) leave, and the
  rest crosses over.
- **Cross-over:** the low-pressure trunk line between IP and LP is big
  enough to store meaningful steam — state 15 (`rcro`), one more mass
  balance. Its conditions (≈173 psia, 709 °F) were the
  [CRSTAT story's](@basics/steam-tables) crime scene.
- **LP:** the final expansion into vacuum, largest enthalpy drop
  (≈380 Btu/lbm), with the last extractions (`wlhst`) feeding the LP
  heaters, and exhaust — ≈93% quality — into the
  [condenser](@plant/condenser).

Every arrow above is one line in `PowerPlant.steamPathAndTurbines`;
here is the IP exit as a specimen:

```matlab
sig.wipo = sig.wip - sig.w2hhs - sig.w3hhs - sig.wipftx;
```

## One shaft

All three cylinders share the shaft with the generator: their powers
sum (`mwtro = mwhp + mwip + mwlp`) and drive the
[swing dynamics](@basics/generator-grid) — states 16 and 47 — while the
grid's electromagnetic spring holds the whole train at 377 rad/s. The
train has enormous *thermal* flexibility (any admission from ~0 to
110%) but essentially no *speed* flexibility: synchronized, it turns at
grid frequency or it trips.

## What stresses it

- **Test 1–4 (load ramps):** pure admission transients — governor
  valves, steam chest, `p1st` all in the front line; the cylinders
  themselves just follow flow.
- **Test 6 (frequency drop):** the governor rails trying to serve an
  impossible speed/load demand; the train gets dragged to 352 rad/s by
  the grid and the *whole* admission chain saturates.
- **Overspeed (not simulated):** the reason `wiv` exists. Lose the
  generator's spring (breaker opens) and stored steam in the reheater
  and cross-over — states 13 and 15 — would race the shaft; intercept
  and governor valves both slam. The model carries the valve so its
  pressure drop and plumbing are faithful, not to run that scenario.

::: metrics The train at 100% load
| Quantity | Value |
|---|---|
| Admission | 1109 lbm/s at 2415 psia / 1000 °F |
| Cylinder powers | HP ≈167 MW; IP + LP carry the balance to 600 |
| Shaft speed | 377 rad/s (3600 rpm) |
| Cross-over storage state | ≈173 psia, 709 °F (`rcro`) |
| Extraction stations | 6 taps + FP-turbine supply |
:::

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| steam chest state | `xdot(12)` on `rsco`; `whp = khp·√(rsco·psco)` | `model.PowerPlant` |
| cross-over state | `xdot(15)` on `rcro`; `wlp = klp·√(rcro·pcro)` | `model.PowerPlant` |
| flow ledger | `whpo`, `wrh1`, `wipo`, `wlpo` chains | `PowerPlant.steamPathAndTurbines` |
| extraction fits | thesis HPEXT / IPEXT / LPEXT | `model.Turbomachinery` |
| intercept valve | `wiv = kip·aiv·√(rrho·prho)` | `model.PowerPlant` |
:::

Next: the [condenser](@plant/condenser) — where the cycle closes and
the vacuum that makes the LP cylinder worth having.
