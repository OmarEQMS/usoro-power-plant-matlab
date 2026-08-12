# Next steps

Open investigations and improvements, in rough priority order. Context for
all of them: `model.md` (current model, validation results, known offsets),
`model_old.md` (legacy code and the crstat/kjtre findings),
`thesis_notes.md` (thesis summary and FORTRAN-listing landmarks).

**Status of the former must-haves** (all completed Aug 11, 2026):

- constants verification and reheat set-point check — done, results folded
  into investigation 1 below and `model.md` "Known quantitative offsets";
- permanent regression harness — `src/tools/validate_against_legacy.m`
  (127 sample points + dual-RK4 run, all exact; also guards both halves of
  the kjtre correction contract). Run it after any edit to `+model` or
  `src/old`;
- `kjtre` comment in `src/old/const1.m` — in place.

## 1. The uniform fuel/air offset (main investigation)

**Symptom (restated after the Aug 2026 verification session).** The model
needs ≈10% more fuel and air than the thesis's published steady states to
hold the same steam conditions, at every load — not, as first thought,
only at partial load:

| Signal | This model | Thesis (Tables V.1–V.3) |
|---|---|---|
| Fuel at 77.5% trim | 69.6 lb/s (cfld 4.10 V) | 63.3 lb/s (3.81 V) |
| Air at 77.5% trim | 1068.9 lb/s | 972.1 lb/s |
| Air/fuel ratio | 15.35 | 15.36 (same) |
| Fuel at 50% trim | 46.5 lb/s | ~42 (Table V.3 scaled) |
| 100% self-trimmed | air rails at 5 V, sags to ≈2000 psia | holds 2415 psia at 80.1 lb/s |

The published 100% "match" (80.14 vs 80.1 lb/s) is the thesis ICs evaluated
at t = 0; they are not an equilibrium of this model (residuals ~0.5 vs
~1e-3 at the trimmed points). Every capability limit follows from this one
offset: Test 4 tops out at ≈485 MW, Test 6 settles at ≈470 MW/1857 psia,
and the self-trimmed 100% point saturates the same way.

**Established (Aug 11, 2026), i.e. what the offset is *not*:**

- *Not a control-constant transcription bug.* Every constant in the tilt,
  gas-recirc, reheat, superheat, boiler-master and transducer-range groups
  matches the thesis data deck exactly, read from the scanned pages
  (printed pp. 278–286), including the OCR-garbled gas-recirc block
  (`KC1GR=0.004, KTC1GR=20, KC2GR=12, KC3GR=1`) and `K2NG=72.201`.
- *Not the reheat loop misbehaving.* `trho` sits exactly on its (clamped)
  schedule at all three trims; the tilt is neutral (|xgg| < 3°, inside the
  ±5° deadband) and the recirc integrator is frozen at every trim.
- *Not the gas-recirculation level.* The recirc steady value is
  path-dependent within a narrow attractor band (≈355–385 lb/s at 77.5%;
  re-seeded at the thesis's 337 or at the 100% value, the plant pumps it
  back into the band). Fuel changes < 0.1% across the band — the recirc
  offset is a *consequence* of the same heat balance, not a cause.
- Appendix C schedules the reheat set point on `WSSO` where the program
  listing uses `WHP` (we follow the listing); identical at steady state.

**Where the ~110k Btu/s at 77.5% actually goes (open):** our absorbed
fraction is 80.0% of fuel heat at 77.5% (thesis-implied ≈88%), and the
stack-side gas temperature *rises* from 100% to 77.5% (1105 → 1124 R)
because total furnace gas flow at 77.5% exceeds the 100% value. Remaining
concrete checks, in order of promise:

1. **Air/gas network verification (prime suspect).** At the exact thesis
   100% IC state, `Hydraulics.airGas` delivers war = 1181.7 lb/s where
   thesis Table V.1 reports 1230.3 (−4% at identical inputs). Verify the
   `arflow` transcription line-by-line against the printed FORTRAN (OCR
   has no ARFLOW header — find it in the listing; HXFER is at OCR line
   ≈11078, AVERAG ≈11145) the way `crstat` was caught.
2. **Furnace/convective chain verification.** Same treatment for
   `HeatTransfer.furnace`/`convective` vs the printed listing (furnace
   section in the main program ≈ OCR 9400–9600) — a crstat-class slip in
   one absorption equation would explain the uniform deficit directly.
3. **Energy-balance audit completion.** Account for the full gas-side
   ledger at 77.5% (absorptions + stack loss + the fixed-temperature air
   heater `ktat/ktahad/ktapad` treatment) and identify the sink that eats
   the extra ~110k Btu/s relative to the thesis-implied balance.
4. **Feedwater-heating degradation (secondary, ~1% of fuel).** Our `hhho`
   falls faster with load than the thesis's (441.4 vs 454.1 Btu/lb at
   77.5%; 411.7 vs 437.3 at 50%; exact at 100%). Suspect the extraction /
   heater chain (`hpext`/`ipext`/`lpext` fits, `qhh` with the raised
   `hcro`). Also the likely driver of the slow `heco`/`hhho` trim drift
   (section 3).
5. **Fit-range check (deprioritized).** `crstat`'s corrected cross-over
   enthalpy (≈1380 Btu/lb at ≈173 psia/709 °F) is consistent with real
   steam tables, so the fix itself is sound at the new regime; a broader
   sweep of the 16 fits vs steam tables remains useful hygiene.

If 1–3 come back clean, the remaining explanation is that the thesis's
published tables/figures were produced with a different code or data-deck
version than the printed listing — unfalsifiable except by exhausting the
listing verification.

## 2. Coordinated Control Mode

The thesis modeled it but ran all published tests boiler-following: the
code carries the scheduled throttle set point `kpsso = k1pss + k2pss·ldc`
and then overrides it with the constant `k4pss = 2415` (see
`ControlSystem.derivatives`, boiler-master section). Adding a
`ControlSystem` mode flag that skips the override would enable
coordinated-mode experiments — sliding-pressure-style operation the thesis
mentions but never plots.

## 3. Smaller items

- **Rate feedforwards ("falta"):** `fc2dv`, `fcp1st`, `fctrho`, `fcxgg`
  are stubbed to zero (as in the legacy code). Implement them as proper
  filtered derivatives of `c2dv`, `cp1st`, `ctrho`, `cxgg` (the thesis
  block diagrams' d/dt compensation) and see whether the deaerator /
  temperature loops tighten.
- **Boiler-master anti-windup:** the integrator state `c3md` grows without
  bound whenever the pressure set point is unreachable (Tests 6, 7). Its
  limited copy is what acts, so behavior is correct, but a conditional
  integrator (stop integrating while `c4md` is clamped) would match the
  analog hardware's saturation and keep states bounded. The gas-recirc
  integrator `c2gr` can wind up the same way while the tilt is outside its
  deadband.
- **40% voltage-drop variant of Test 5:** thesis text (p. 55) says the
  condensate pumps then fail to meet demand and the deaerator level falls
  toward a trip — one line with `model.GridProfile` to reproduce.
- **Slow trim drift:** the trim residuals never reach zero (`heco`/`hhho`
  drift ~1e-3 at 50%). Likely the same economizer/heater-chain imbalance
  as investigation item 4 above.
- **DYSYS TSTEP curiosity:** the thesis's run deck (printed p. 288) says
  `TSTEP=0.4`, while the text (p. 49) describes RK4 at 0.1 s. Worth a note
  if integration-step sensitivity ever comes up; RK4 at 0.1 s is what this
  project uses throughout.

## 4. Larger optional builds

- **Standard Model (27th order, thesis Appendix B):** the reduced
  analog-computer model — would allow reproducing the thesis's V.2/V.4/V.6/
  V.8 comparison figures and give a fast model for control design. Beware:
  its data deck (OCR lines ≈12300+) lists different values/units for
  same-named constants (`KC2GR=0.8`, `KUWWGM=186.19`, and Appendix C's
  `KUWWGM=73.801+1.4173*WFL`).
- **Thesis Tests we cannot verify:** the remaining thesis materials
  (per-test driver code, coordinated-mode runs) are not in the scanned
  listings; any reproduction beyond Figs. V.1–V.11 is uncheckable.
