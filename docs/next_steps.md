# Next steps

Open investigations and improvements, in rough priority order. Context for
all of them: `model.md` (model architecture, validation results, known
offsets) and `thesis_notes.md` (thesis summary and FORTRAN-listing
landmarks).

Resolved investigations (the HXFER fuel/air offset chief among them) are
recorded in `model.md` ("Known quantitative offsets") and on the site's
changelog page (`ui/content/plant/changelog.md`); this file lists only
what is still open.

## 1. Coordinated Control Mode

The thesis modeled it but ran all published tests boiler-following: the
code carries the scheduled throttle set point `kpsso = k1pss + k2pss·ldc`
and then overrides it with the constant `k4pss = 2415` (see
`ControlSystem.derivatives`, boiler-master section). Adding a
`ControlSystem` mode flag that skips the override would enable
coordinated-mode experiments — sliding-pressure-style operation the thesis
mentions but never plots.

## 2. Smaller items

- **Test 7 settles high:** the fan-loss recovery sits ≈25–30 MW above
  Figure V.11 (448 vs ≈420 MW, 1796 vs ≈1700 psia) — the one test the
  fan-curve calibration moves slightly *away* from the thesis (its
  single surviving fan pair benefits from the stronger fan curves).
  Candidate explanations if anyone digs: the thesis run may have used
  the printed (weaker) fans, or its single-fan network differs in a way
  the scan doesn't show. All other tests land on the figures.
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

## 3. Larger optional builds

- **Standard Model (27th order, thesis Appendix B):** the reduced
  analog-computer model — would allow reproducing the thesis's V.2/V.4/V.6/
  V.8 comparison figures and give a fast model for control design. Beware:
  its data deck (OCR lines ≈12300+) lists different values/units for
  same-named constants (`KC2GR=0.8`, `KUWWGM=186.19`, and Appendix C's
  `KUWWGM=73.801+1.4173*WFL`).
- **Thesis Tests we cannot verify:** the remaining thesis materials
  (per-test driver code, coordinated-mode runs) are not in the scanned
  listings; any reproduction beyond Figs. V.1–V.11 is uncheckable.
