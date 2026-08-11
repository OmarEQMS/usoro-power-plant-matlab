# Next steps

Open investigations and improvements, in rough priority order. Context for
all of them: `model.md` (current model, validation results, known offsets),
`model_old.md` (legacy code and the crstat/kjtre findings),
`thesis_notes.md` (thesis summary and FORTRAN-listing landmarks).

**Must-haves** (protect the correctness of what already exists):

- the *verification* half of investigation 1 below (checks 1–2: constants
  vs. the thesis data deck, reheat set-point check) — this project has
  already caught two transcription/units bugs, and the partial-load offset
  has the fingerprint of a third (exact at the 100% anchor point, growing
  away from it); until those constants are verified, capability results
  (Test 4's ≈485 MW ceiling, Test 6's ≈470 MW settle) are provisional;
- the **permanent regression harness** (item 3a) — the bit-for-bit
  equivalence proof currently exists only in a past working session and is
  unverifiable after any future edit without it;
- the **`kjtre` comment in `src/old/const1.m`** (item 3b) — guards against
  a silent double-correction if anyone "fixes" the legacy value
  (`gen_parameters.m` applies the /32.174 itself).

Everything else is an extension: valuable, but nothing breaks without it.

## 1. The partial-load fuel / gas-recirculation offset (main investigation)

**Symptom.** At the trimmed 77.5% operating point the corrected model burns
more fuel and recirculates more flue gas than the thesis run:

| Signal (77.5%) | This model | Thesis (Fig. V.9 / Table V.2) |
|---|---|---|
| Fuel demand `cfld` | ≈4.18 V (≈71.5 lb/s) | ≈3.81 V (63.3 lb/s) |
| Gas recirc demand `cgrd` | ≈4.2 V (≈400 lb/s) | ≈3.70 V (≈337 lb/s) |
| Air demand `card` | ≈4.0 V | ≈3.41 V |

At 100% (thesis initial conditions) the model *is* in balance with the
thesis fuel value (80 lb/s), so the offset grows toward partial load.

**Why it matters.** The extra recirculation loads the ID fans and the extra
fuel demand sits closer to the 5 V rail, so every test that pushes toward
maximum capability saturates early: Test 4 tops out at ≈485 MW instead of
recovering to 600; Test 6 settles at ≈470 MW/1857 psia vs the thesis
537/2125. Transient shapes and mechanisms match; the saturation margins
don't.

**Hypotheses and concrete checks:**

1. **Reheat-side chain.** The crstat fix raised the cross-over enthalpy
   (1210 → 1380 Btu/lb), changing the reheat/IP energy split. If the
   reheater now runs cold relative to its set point, the tilt control
   drives `cxggd` up and the recirc follows (`c1gr = cxggd − kcxgg`).
   Check in a 77.5% steady run: does `trho` actually sit on its schedule
   `ktrh = k1trh + k2trh·whp`? How far up is the tilt `xgg`?
2. **Verify the tilt/recirc constants against the thesis data deck**
   (OCR listing, lines ≈11400–12300 — beware the *Standard Model* deck
   starting ≈12300 lists different values/units): `kcxgg`, `kc1ry`,
   `kc1rh/kc2rh/kc3rh`, `k1tgr/k2tgr`, `k1xgg/k2xgg`, the gun-count
   factors `k1ng..k5ng`/`kxwwe`, and `kuwwgm`. A single mistyped schedule
   constant could explain the whole offset.
3. **Energy-balance audit at 77.5%.** Tabulate `qps/qss/qrh/qec/qwwgm`
   and the fuel heat input `wfl·khfl` at our trim vs what thesis Table V.2
   implies (air 972 lb/s, fuel 63.3 lb/s). Identify which absorption is
   low, forcing extra firing.
4. **Recirc contribution isolation.** Re-trim 77.5% with
   `ctrl.gasRecircEnabled = false` and compare fuel demand; quantifies how
   much of the offset is the recirc loop reacting vs the base heat balance.
5. **Fit-range check.** The `crstat`/`rhstat` polynomial fits are now
   evaluated at a different cross-over regime (≈173 psia/709 °F). Spot-check
   the fits against real steam tables there; a fit extrapolating poorly
   would bias the reheat balance.

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
  analog hardware's saturation and keep states bounded.
- **40% voltage-drop variant of Test 5:** thesis text (p. 55) says the
  condensate pumps then fail to meet demand and the deaerator level falls
  toward a trip — one line with `model.GridProfile` to reproduce.
- **(3a) Permanent regression harness:** promote the session's A/B
  validation into `src/tools/validate_against_legacy.m` (pointwise vs
  `src/old/digpte47`, aware that `xdot(16)` differs by exactly 32.174).
- **(3b) Comment in `src/old/const1.m`:** a comment-only note next to
  `kjtre=625000.0` pointing at the units correction, so readers of the
  legacy code aren't misled (no behavior change; keep the value as-listed
  there — `gen_parameters.m` applies the correction and would double-apply
  if the legacy value were changed).
- **Slow trim drift:** the trim residuals never reach zero (`heco`/`hhho`
  drift ~1e-3 at 50%). Establish whether this is a genuine very slow plant
  mode or a small inconsistency between the economizer/heater fits.

## 4. Larger optional builds

- **Standard Model (27th order, thesis Appendix B):** the reduced
  analog-computer model — would allow reproducing the thesis's V.2/V.4/V.6/
  V.8 comparison figures and give a fast model for control design.
- **Thesis Tests we cannot verify:** the remaining thesis materials
  (per-test driver code, coordinated-mode runs) are not in the scanned
  listings; any reproduction beyond Figs. V.1–V.11 is uncheckable.
