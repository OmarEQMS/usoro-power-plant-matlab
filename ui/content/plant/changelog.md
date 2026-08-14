---
description: Every correction made on the way to the current model — the symptom, how it was found, the root cause, and what it changed.
---

# Model changelog

This model is a hand transcription of a 1977 thesis: a printed FORTRAN
listing, a scanned data deck, and published tables and figures that do
not always agree with each other. Transcriptions drift, and this page
is the honest record of every correction applied on the way to the
current model — in the order they were found, each with its symptom,
its root cause, and its effect. Every other page on this site
describes only the current model; the history lives here.

::: why
Two reasons. *Auditability*: every "matches Figure V.n" claim on the
[tests page](@plant/emergency-tests) is only as strong as the chain of
corrections behind it, so the chain should be public. And *method*:
how each defect was found — an oracle that would not close, a figure
that could not be reproduced, a scan read character by character — is
a working manual for finding the next one.
:::

## 1. Un-freezing the speed states

- **Symptom** — the original port (2024) hardcoded the feed pump and
  turbine-generator speed derivatives to zero: with them live, the
  simulation blew up.
- **Root cause** — the integration scheme, not the physics. The
  original driver integrated a frozen derivative (effectively explicit
  Euler), and Euler [diverges on the undamped swing
  pair](@basics/numerical-integration) no matter the step size.
- **Change** — a true 47-state derivative $f(t,x)$ integrated with
  fixed-step RK4 at 0.1 s, the thesis' own DYSYS scheme. All 47
  states live; the [swing pair](@basics/generator-grid) rings
  undamped, as designed.

## 2. Cross-over steam anchoring (CRSTAT)

- **Symptom** — the feed pump turbine's torque balance would not close
  at the thesis' published initial conditions.
- **Root cause** — a scan ambiguity: the isentropic-efficiency
  anchoring line reads `HO=H1-E*(H1-HI)` (inlet-anchored), and the
  low-resolution scan made the misreading easy.
- **Change** — `crossoverSteam` anchored per the listing; the torque
  balance then closes to four digits at the p. 288 state. The
  [steam-tables page](@code/steam-tables) keeps the lesson: physics
  audits the math.

## 3. Turbine-generator inertia units (`kjtre`)

- **Symptom** — Test 6's ride-through was impossible: on the
  60 → 56 Hz grid ramp the generator pole-slipped and the plant
  collapsed, flatly contradicting Figure V.10.
- **Root cause** — the deck lists `KJTRE=625000`, which taken as
  slug·ft² implies an inertia constant H ≈ 88 s — an order of
  magnitude beyond any real machine. It is a vendor-style $WR^2$ in
  lbm·ft².
- **Change** — `kjtre = 625000/32.174` (H ≈ 2.7 s, physical) in the
  generated `Parameters`; the other rotor inertias validated
  as-listed through Test 5's coast-down time constants.

## 4. Convective mean specific heat (HXFER)

The big one — a single character.

- **Symptom** — every trimmed operating point needed ≈10% more fuel
  and air than the thesis' published tables, at every load; Test 4
  capped near 485 MW with the air demand railed.
- **Found** — by reading the *scanned* printed listing line by line
  (the OCR text garbles exactly the characters that matter) after an
  energy audit showed the absorbed fraction of fuel heat was 80%
  where the thesis implied ≈88%.
- **Root cause** — the mean gas specific heat over a convective bank
  is `SG=Z1+Z2*(TG1+TGO)` in the listing — a **plus**, because the
  fitted specific heat is linear in temperature and the mean over
  inlet and outlet keeps the sum. The port had a minus,
  under-counting the heat delivered by all four
  [convective banks](@code/heat-transfer).
- **Change** — the plus sign, in both the current model and the
  archived flat-script port. Absorbed fraction 80% → 87.6%; the
  trimmed points land on Tables V.1–V.3 (77.5%: fuel 63.6 vs 63.3
  lb/s, air 977 vs 972); Test 4 reaches rated power; the p. 288
  initial conditions became a near-equilibrium of the model.

## 5. Integrator anti-windup (limiter write-back)

- **Symptom** — through long saturations (Tests 4, 6, 7) the control
  integrator states drifted far past their 5 V rails, and Test 4 rang
  harder than Figure V.7.
- **Root cause** — a semantics gap: the FORTRAN passes integrator
  states to its limiter subroutines *by reference*, so the stored
  states themselves saturate — analog hardware's free
  [anti-windup](@basics/control-basics). The port clamped copies
  only.
- **Change** — `ControlSystem.clampStates`, applied by the
  [Simulator](@code/simulator) after every RK4 step: integrator
  states pin at their rails and release the instant the error
  reverses.

## 6. Rate feedforwards

- **Change** — the d/dt compensation signals of the thesis block
  diagrams (`fc2dv`, `fcp1st`, `fctrho`, `fcxgg`), previously left at
  zero, implemented as the listing computes them: per-step backward
  differences of the [loop signals](@plant/loops-steam) they watch.
  Their deck gains are ±0.01, so the effect is small — implemented
  for fidelity, not performance.

## 7. Fan-curve calibration (the air ceiling)

- **Symptom** — the plant could not *hold* 100%: under constant
  full-load demand it limit-cycled 574–606 MW with a ~400 s period,
  the air vanes railed at 5 V; Test 4 reached rated power but orbited
  it, and Test 6 settled ≈4% under its figure.
- **Found** — by static probing of the [air-gas
  network](@plant/air-gas-path) at the 100% state: the printed deck
  delivers at most ≈1219 lbm/s of air with both vane sets fully open,
  while the [cross-limit](@plant/loops-combustion) needs 1230.0 lbm/s
  to sustain rated fuel — and the initial-condition state itself says
  its vane command (≈4.55 V) delivers 1230.3, which the printed
  ARFLOW cannot produce at *any* command. The published runs used
  stronger fans than the printed listing.
- **Root cause** — a table-vs-listing inconsistency inside the thesis
  itself: its published steady states (Tables V.1–V.2, Figs. V.7,
  V.10) are unreachable with its own printed fan coefficients.
- **Change** — `kfcal = 1.10` on the six fan ΔP coefficients in
  `airGas` (mirrored in the archived port): same fan speeds and vane
  law, 10% more head, ≈5% more deliverable air. The value is pinned
  by the published *off-design* data — ×1.10 lands Test 6's
  speed-limited settle on Figure V.10 (535.5 MW / 2115 psia vs
  ≈537 / 2125), while the ×1.23 that would exactly reproduce the
  4.55 V vane reading overshoots it, as does a friction-side
  calibration. Result: the 100% point holds indefinitely
  (600.0 MW / 2415.0 psia), Test 4 climbs and locks onto Table V.1's
  state, Test 3's pressure dip and overshoot tighten onto Figure V.5.

## Known residuals

What the current model does *not* resolve — all documented in the
repository's engineering notes, all traced to the thesis' own
materials rather than to the port:

- **Test 7 settles high.** The fan-loss recovery lands ≈25–30 MW
  above Figure V.11 (448 vs ≈420 MW). It is the one test the
  fan-curve calibration moves slightly *away* from the thesis — its
  surviving fan pair also benefits from the stronger curves — and so
  the one datum mildly against ×1.10.
- **Two flavors of "100%".** Evaluated through the verified valve and
  turbine equations, the p. 288 initial state passes ≈853 lbm/s of
  main steam, while Table V.1 lists 1109.2 for the same nominal
  point — a thesis-internal inconsistency. They are two different
  near-equilibria; the tables/figures side is what the tests
  reproduce.
- **Deaerator pressure** sits a few psi under the tables at the
  trimmed points (45.3 published vs ≈42 at 77.5%) — small, open, and
  the likely cause of the slow enthalpy trim drift.

::: code-map Where the changes live
| Change | Code | Where |
|---|---|---|
| true derivative + RK4 | `derivative`, `step` | `model.Simulator` |
| CRSTAT anchoring | `crossoverSteam` + comment | `model.SteamTables` |
| inertia units | `kjtre = 625000/32.174` | `model.Parameters` (generated) |
| HXFER sign | `sg = z1 + z2*(tg1 + tgo)` | `HeatTransfer.convective` |
| anti-windup | `clampStates`, per-step | `model.ControlSystem`, `Simulator.step` |
| rate feedforwards | `fc2dv` … `fcxgg`, `rateFeedforwardsEnabled` | `model.ControlSystem` |
| fan-curve calibration | `kfcal = 1.10` on the fan ΔP coefficients | `Hydraulics.airGas` |
| equivalence guard | `validate_against_legacy` | `deprecated/tools/` |
:::

This really does close the Power Plant section. The
[Code section](@code/tour) retraces the same machine, file by file.
