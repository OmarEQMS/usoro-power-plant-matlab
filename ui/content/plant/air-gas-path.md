---
description: FD and ID fans, the balanced-draft furnace, and the recirculation tap — one closed-form network solve moving 1400 lbm/s of air and gas.
---

# Fans and the air/gas path

Steam gets four pages; the gas that heats it gets this one — and one
network solve in the code. Two pairs of fans move ≈1400 lbm/s through
the plant: **FD (forced draft) fans** push fresh air in, **ID (induced
draft) fans** pull flue gas out, and between them the furnace sits at a
carefully held 14.7 psia. A third path taps cooled gas back to the
furnace for [reheat temperature support](@plant/reheater).

::: why
Air is the plant's hard capability limit. Steam-side components can be
pushed; but if the fans cannot deliver the air, the
[cross-limits](@basics/control-practices) hold back fuel, and megawatts
stop there. Every test that saturates — 4, 6 and 7 — saturates *here*
first.
:::

## The path

**Air side:** FD fans (state 21, `nfd`) draw ambient air through inlet
vanes (`avf`, the air controller's actuator), push it through the
[air heater](@plant/economizer-airheater) — arriving at the burners at
948 °R — and into the furnace with the fuel.

**Gas side:** combustion products plus recirculated gas
(`wwwg = war + wfl + wgr`) sweep the
[convective banks](@basics/heat-transfer) in order, exit the economizer
at ≈1105 °R, give their last heat to the air heater, and reach the ID
fans (state 22, `nid`), whose inlet vanes (`avi`) belong to the furnace
pressure controller. Then the stack.

**Recirculation:** after the economizer, a controlled tap (`wgr`, up to
500 lbm/s) returns cool gas to the furnace floor — dilution for the
radiant/convective split, as the [furnace page](@plant/furnace) covered.

## Balanced draft

The furnace itself is held at atmospheric pressure — in practice a hair
below it:

::: definition Balanced draft
FD fans push in; ID fans pull out; the furnace pressure `pfn` floats on
their balance. The furnace-pressure loop trims the ID vanes to hold
14.7 psia, keeping the box slightly sub-atmospheric so that any leak
draws air *in* rather than blowing flame and flue gas *out* at the
operators. A furnace "puff" is a real industrial accident mode; this
loop is a safety system that happens to do process control.
:::

The coupling is tight and fast: more air demand opens FD vanes, which
would pressurize the furnace, so the ID vanes must follow within
seconds. The loop's structure even carries an air-flow feedforward term
for this — though the thesis deck sets its gain (`kc2fn`) to zero, so
in practice the ID vanes chase the pressure error, fast.

## One solve for the whole path

All of it — two fan curves (speed states, [affinity
rules](@basics/pumps-fans)), two vane resistances, air heater, furnace,
banks, stack friction — collapses into one closed-form network solve:

```matlab
[sig.war, sig.wwwg, sig.wfd, sig.wgo, sig.wid, sig.pahao, sig.pfdo, ...
    sig.pfn, sig.pecgo, sig.papgo, sig.pido, sig.efd, sig.eid] = ...
    model.Hydraulics.airGas(P.knfd, P.knid, s.nfd, s.nid, ...
        u.wgr, u.wfl, u.avf, u.avi);
```

Note the first two arguments: `knfd`, `knid` — the **number of operating
fan pairs**. They are configuration constants, not states, which is why
Test 7 (losing one FD+ID pair at full load) is simulated as two phases
stitched at the failure instant: same model, `2 → 1`, and the surviving
pair suddenly faces the whole system curve. Power dips to ≈410 MW and
claws back to ≈448 — air-limited, exactly as this page predicts.

## The fans in the emergencies

- **Test 5 (voltage dip):** motor torque falls with $V^2$; the big fan
  rotors (inertias ≈185,000 slug·ft²) coast down over ~100 s and settle
  slightly slow — visible, mild.
- **Test 6 (frequency drop):** synchronous speed itself falls 6.7%; fan
  [affinity](@basics/pumps-fans) turns that into ≈13% less head. Air
  demand rails at 5 V, the cross-limit caps fuel, and the plant settles
  at ≈535 MW — the fans, not the boiler, set that number.
- **Test 7 (pair loss):** the brute-force version of the same lesson.

::: metrics The path at 100% load
| Quantity | Value |
|---|---|
| Air `war` / fuel `wfl` / recirc `wgr` | ≈1230 / 80 / ≈184 lbm/s |
| Furnace gas `wwwg` | ≈1490 lbm/s |
| Furnace pressure `pfn` | 14.7 psia (set point) |
| FD / ID fan speeds | 61.9 / 92.5 rad/s |
| Operating pairs `knfd`/`knid` | 2 / 2 |
:::

::: note The calibrated fan curves
The 100% point needs air ≈ 15.35 × 80.1 ≈ 1230 lbm/s through the
[cross-limit](@plant/loops-combustion), and the fan ΔP coefficients in
`airGas` carry a ×1.10 calibration (`kfcal`) so the network can supply
it: fans of the printed speed and vane law developing 10% more head,
≈5% more deliverable air, a full-open ceiling of ≈1267 lbm/s — about 3%
of margin above rated, which is what lets the unit hold 100% with the
vanes at ≈91% and lets Test 6's speed-limited fans land on their
figure. The calibration is pinned by the thesis's published steady
states (Table V.1's 1230.3 lbm/s of air at ≈4.55 V of vane command);
the story of how it was found is on the
[changelog](@plant/changelog).
:::

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| the network solve | `airGas(...)` (thesis ARFLOW) | `model.Hydraulics` |
| fan speed states | `xdot(21)`, `xdot(22)` torque balances | `model.PowerPlant` |
| vane commands | `avf` ← `card`, `avi` ← `cfnd` | `ControlSystem.actuatorCommands` |
| pair counts | `knfd`, `knid` (Test 7 flips 2→1) | `model.Parameters`, `test.run7` |
:::

Next: [The turbine train](@plant/turbine-train) — following the steam
through the machines that spend it.
