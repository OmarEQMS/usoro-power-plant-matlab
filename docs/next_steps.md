# Next steps

Open investigations and improvements, in rough priority order. Context for
all of them: `model.md` (model architecture, validation results, known
offsets) and `thesis_notes.md` (thesis summary and FORTRAN-listing
landmarks).

Resolved investigations (the HXFER fuel/air offset chief among them) are
recorded in `model.md` ("Known quantitative offsets") and on the site's
changelog page (`ui/content/plant/changelog.md`); this file lists only
what is still open.

## 1. Test 4 limit cycle at the air ceiling

Test 4 reaches rated power (peaks ≈603–607 MW, pressure recovering to
≈2435 psia each swing) but orbits the 100% point (≈565–605 MW, 2240–2440
psia, ~400 s period) instead of settling like Figure V.7. Root cause of
the residual: the 100% point needs air ≈ 15.35 × 80.1 ≈ 1230 lb/s, but
the printed deck's air network delivers at most ≈1219 lb/s with both
dampers full open at the IC fan speeds (`air_probe`: reaching 1230.3
would need damper area ≈1.02). Thesis Table V.1 reports 1230.3 lb/s *at*
its 100% steady state with the air control at only ≈4.55 V (Fig. V.7) —
i.e. the thesis's published run had a few percent more air delivery at a
given damper signal than its own printed listing provides. With zero air
margin, the cross-limit caps fuel ≈1% short on average, the boiler
integrates the deficit, and the tilt/spray/recirc loops swing along
(tilt ±15°+, spray 3–64 lb/s over a cycle). Options if a settle is ever
wanted: treat the air-side capacity constants as the remaining
table-vs-listing inconsistency (unfalsifiable from the scan alone), or
accept the cycle as this deck's faithful behavior.

## 2. Coordinated Control Mode

The thesis modeled it but ran all published tests boiler-following: the
code carries the scheduled throttle set point `kpsso = k1pss + k2pss·ldc`
and then overrides it with the constant `k4pss = 2415` (see
`ControlSystem.derivatives`, boiler-master section). Adding a
`ControlSystem` mode flag that skips the override would enable
coordinated-mode experiments — sliding-pressure-style operation the thesis
mentions but never plots.

## 3. Smaller items

- **40% voltage-drop variant of Test 5:** thesis text (p. 55) says the
  condensate pumps then fail to meet demand and the deaerator level falls
  toward a trip — one line with `model.GridProfile` to reproduce.
- **Slow trim drift / deaerator offset:** the trim residuals never reach
  zero (`heco`/`hhho` drift ~1e-3 at 50%), and deaerator pressure sits a
  few psi under Table V.2 (45.3 published vs ≈42 at 77.5%). Both point at
  a small feedwater-heater/extraction-chain imbalance
  (`hpext`/`ipext`/`lpext` fits, `qhh`).
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
