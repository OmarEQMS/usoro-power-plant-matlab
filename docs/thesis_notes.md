# Usoro (1977) — thesis notes

Everything gathered from reading the thesis itself, independent of the MATLAB
port. For the mapping between thesis equations and this repository's code, see
[model.md](model.md).

## Bibliographic record

> Patrick Benedict Usoro, *"Modeling and Simulation of a Drum Boiler-Turbine
> Power Plant Under Emergency State Control"*, M.S. thesis, Department of
> Mechanical Engineering, Massachusetts Institute of Technology, submitted
> May 12, 1977. 305 pages. Advisor: Prof. D. N. Wormley.

- Item page: <https://dspace.mit.edu/handle/1721.1/16301>
- PDF (5.5 MB scan): `https://dspace.mit.edu/server/api/core/bitstreams/63ae6b5e-24e8-4268-9aea-4a08803aab07/content`
- OCR text (252 KB, grep-able): `https://dspace.mit.edu/server/api/core/bitstreams/2f641bd8-1131-4d8c-8385-9f1895117919/content`
- The old-style `bitstream/handle/...` URLs no longer work; use the DSpace 7
  REST endpoints above.
- Work performed under MIT's Emergency State Control Project (Contract
  E49-18-2075), in collaboration with the group of Profs. G. L. Wilson and
  F. C. Schweppe.

**OCR caveats:** the scan garbles subscripts, Greek letters, and — critically —
cannot distinguish `1` from `I` in the FORTRAN listings (this ambiguity is
exactly how the `crstat.m` transcription bug described in model.md happened).
Treat any OCR-read equation as a hypothesis and verify it numerically against
the initial-condition tables.

## The two models

| | Digital Computer Model | Standard Model |
|---|---|---|
| Order | **47** (23 physical + 24 control) | **27** (12 physical + 15 control) |
| Purpose | accurate simulation of normal + emergency operation | analog-computer implementation |
| Equations | Appendix A | Appendix B |

The Standard Model was derived from the Digital Model by (p. 37):
- lumping components (primary SH + spray + secondary SH → one superheater;
  reheater + reheat spray → one reheater; IP turbine + cross-over + LP turbine
  → one equivalent LP turbine);
- simplifying heat-transfer and flow nonlinearities (verified against Digital
  Model simulations);
- replacing pump/fan dynamics with auxiliary circuits that only model the
  voltage/frequency limitations;
- assuming perfect control for well-behaved sub-loops (feedwater flow,
  condensate flow, feedpump turbine, furnace pressure).

Distinguishing features Usoro claims over prior boiler-turbine models (pp. 11–12):
1. Physically based parameters (geometry, material properties, manufacturer data).
2. Nonlinearities retained → valid over a wide operating range.
3. Steam-table polynomial fits for realistic properties.
4. **Auxiliaries (pumps/fans) modeled with their induction-motor prime movers
   and their dependence on line voltage and frequency** — enabling
   reduced-voltage/frequency emergency simulations.
5. **Feedwater and condensate side dynamics modeled explicitly** — usually
   ignored in the literature, but they can limit plant response and trigger
   trips (proved by Test 5).
6. A real operating plant used as prototype so the model could be verified.

## The prototype plant (Ch. II, pp. 13–14)

An operating (then recently commissioned) **600 MW** unit:

- **Boiler:** oil-fired, balanced draft, controlled-recirculation drum boiler;
  4.2×10⁶ lb/hr steam at 2600 psig / 1005 °F; reheat from 625 °F to 1000 °F.
- **Recirculation:** six pumps; any four sufficient for full load (72 h rating).
- **Draft:** two forced-draft fans (primary air), two induced-draft fans
  (furnace pressure).
- **Feedwater train:** regenerative heating with closed and open (deaerator)
  heaters, six extraction stages; two condensate pumps; combined
  booster + main boiler feed pump driven by an auxiliary steam turbine.
- **Turbine:** tandem-compound single-reheat; HP + IP + two double-flow LP
  elements; 3600 rpm (377 rad/s); throttle 2400 psig / 1000 °F; exhaust
  2 in-Hg abs.
- **Generator:** 685,600 kVA, 3-phase, 60 Hz, 22 kV, hydrogen-cooled,
  0.90 power factor, directly coupled.

## Modeling assumptions (III.1, pp. 24–26)

1. One effective value per cross-section (1-D lumped representation).
2. Transport lags negligible vs. component time constants.
3. Water incompressible w.r.t. pressure (density still varies with temperature).
4. Variation of *pv* negligible vs. variation of *h* (≈12% error in Δu at
   2400 psia/1000 °F — accepted for simplicity).
5. Fluid inertia negligible vs. friction and pressure terms in flow equations.
6. Constant turbulent friction factors (average over the flow range).
7. **Saturated equilibrium in drum, deaerator, and condenser** → one intensive
   property fully defines the state (this is why single densities `rdrs`,
   `rdes` suffice as states).
8. Identical parallel machines are dynamically identical; out-of-service units
   treated as absent (pumps/fans modeled as one unit × count).
9. Heat-exchanger tube metal lumped with the fluid into an effective mass.
10. **Backward difference (outlet condition) representation** — forward
    differencing was found unstable and central differencing gave erroneous
    transients [refs 22, 23, 3].

## Physical-law templates (III.2)

Every component uses one or more of these operational forms:

- Continuity: `V·dρ_out/dt = W_in − W_out`
- Energy: `M·dh_out/dt = W_in·h_in − W_out·h_out + Q − Ẇ`, with effective mass
  `M = ρ_e·V + M_m·S_m·T_m/h_e` (metal lumped into fluid); alternatively
  metal-centered `M_m·S_m·dT_m/dt = Q_in − Q_out` with fluid lumped into metal
  (used for the waterwall, state `twwm`).
- Momentum (inertia-free): `P_in − P_out = f·W²/ρ + L·ρ·g/g_c`
- Rotating machinery (moment of momentum): `J·dN/dt = T_in − T_out`

Constitutive relations: steam-table polynomial fits; pump/fan performance
quadratics in flow and speed; induction-motor torque–slip characteristic
`T = k·V²/(s/s_max + s_max/s)` (explicit V and f dependence — the hook for
Tests 5 and 6).

## Component highlights

- **Turbine chain:** HP efficiency scheduled on flow (`η_hp = 0.589 +
  2.317e-4·W_hp`); IP efficiency constant 0.814; `keip`/`kelp` = 0.93 account
  for interstage extraction; adiabatic relation everywhere is
  `h_out = h_in − η·(h_in − h_isen)`. LP discharge state fixed by condenser
  pressure with constant exhaust steam quality. Storage neglected inside HP/IP
  turbines; steam chest (`rsco`) and cross-over pipe (`rcro`) provide the
  storage states around them.
- **Turbine–generator (pp. 152–153):** `K_jtre·dN_tr/dt = (MW_tro − MW_gn)/N_tr`;
  generator action `MW_gnpu = 2·sin δ`, `dδ/dt = N_tr − N_elec`; infinite bus;
  **damping deliberately ignored**. Rated power ⇔ δ = 30°. This explicit
  mechanical–electrical link is what makes governor droop simulation realistic.
- **Feed pump (pp. 159–160):** driven by an auxiliary steam turbine fed from
  the secondary superheater (low load) *or* IP extraction (normal operation);
  booster pump geared at 1/3 shaft speed; combined head/efficiency quadratics;
  feedwater flow solved in closed form.
- **Furnace:** radiant transfer to waterwalls with burner-tilt correction
  (`tan xgg`) and gun-count factor; waterwall→drum heat `∝ (T_wwm − T_drs)³`.
- **Gas path:** heat exchangers in flue-gas order primary SH → secondary SH →
  reheater → economizer, each `Q = U·(T_gas − T_steam)` with
  `U ∝ k₁·W_g^0.6 + k₂·W_steam^0.8` split gas-side/steam-side.

## Control system (Ch. IV)

Feedforward from the **Load Demand Computer (LDC)** for rapid response with
feedback (P/PI/PID) trims. Three operating modes: Coordinated, Remote
Coordinated (LDC pulsed from the REMVEC satellite control station), and
Manual. Actuators and transducers modeled as linear elements with saturation;
all controller signals live on a normalized 1–5 V scale.

Ten boiler loops (block diagrams Figs. IV.1–IV.6, details + parameters in
Appendix C): throttle pressure (boiler master), air flow, fuel flow (with
air/fuel cross-limits), furnace pressure, feedwater flow (three-element),
feedpump turbine (FW-valve ΔP), condensate flow (deaerator level), superheat
temperature (spray), reheat temperature (burner tilt), gas recirculation.

Turbine control is an Electro-Hydraulic Control (EHC) with Load, Speed, and
Valve control units (Fig. IV.7); partial-arc admission in normal operation,
full-arc for start-up. Speed regulation (droop) acts through `kcvreg`.

## Simulations (Ch. V)

**Numerics:** all runs solved with the DYSYS standard Runge–Kutta routine of
the Joint Mechanical and Civil Engineering Computer Facility, **fixed step
0.1 s** (p. 49). Every test: 10 s at steady state before the disturbance.
All tests run in **boiler-following mode** (throttle set point fixed at
2415 psia) so results could be compared with plant data, although coordinated
mode was modeled and tested. Operating points: 100% (600 MW), 77.5% (465 MW),
50% (300 MW); initial-condition tables on p. 288.

| Test | Scenario | Findings |
|---|---|---|
| 1 (V.1, Figs. V.1–V.2) | Load ramp 100%→77.5% at 15%/min (90 s) | Well behaved; ≈1% power undershoot; throttle pressure rises during ramp, returns to 2415 psia; turbine speed "virtually constant" (electromagnetic spring); drum/deaerator levels rise then recover |
| 2 (V.2, Figs. V.3–V.4) | 77.5%→50% at 15%/min (110 s) | Similar; main-steam/reheat temperature set points change at 50% |
| 3 (V.3, Figs. V.5–V.6) | 50%→77.5% at 15%/min | ≈1% overshoot; behaviors mirror Test 1; **system finds load increase harder than load decrease** |
| 4 (V.4, Figs. V.7–V.8) | 77.5%→100% at 15%/min | Only "fairly well behaved": several control signals saturate, power does not follow demand exactly (no overshoot) — plant near maximum capability |
| 5 (V.5, Fig. V.9) | 30% step voltage drop at 77.5% (4160→2912 V) | Pump/fan speeds drop; controls compensate; steam side nearly unaffected. At **40%** drop the condensate pumps can't meet demand → deaerator level falls → would trip the station. Justifies modeling the water side |
| 6 (V.6, Fig. V.10) | Frequency 60→56 Hz at 0.8 Hz/s | Governor droop forces valves wide open; fans (slower on low frequency) limit air; fuel limited by air cross-limit; settles at 2125 psia and **537 MW (90% of rating)**. Gas-recirculation control deactivated — with it on, settling takes much longer (matches real-plant experience; that loop is often run in manual) |
| 7 (V.7, Fig. V.11) | Loss of one of two FD+ID fan pairs at 100%, no run-back | Air control saturates at 5 V; throttle pressure falls to 1700 psia; max deliverable power **70% (420 MW)**; surviving FD fan slows (615→840 lb/s duty), ID fan speeds up slightly. (Normally a Unit Run-Back to 60% would be forced) |

**Verification (Tables V.1–V.3, pp. 61–63):** steady-state values vs.
manufacturer data agree within 5% at 100% and 77.5% load; within 5% at 50%
except a few condensate-side variables within 10%. No transient plant data was
available for comparison. Reference values worth keeping at hand:

| Variable | 100% | 77.5% | 50% (plant / model) |
|---|---|---|---|
| Power (MW) | 600 | 465 | 300 |
| Main steam flow (lb/s) | 1108 / 1109 | 831 / 813 | 554 / 530 |
| Throttle pressure (psia) | 2415 | 2415 | 2415 |
| Main steam temp (°F) | 1000 | 1000 | 985 / 979.5 |
| Reheat pressure (psia) | 555 / 556 | 419 / 412 | 273 / 263 |
| Drum pressure (psia) | 2735 / 2778 | 2641 / 2604 | 2554 / 2494 |
| Deaerator pressure (psia) | 60.3 / 57.1 | 47.1 / 45.3 | 31.2 / 32.4 |
| LP heater enthalpy (Btu/lb) | 202.5 / 199.0 | 190.2 / 186.7 | 169.3 / 157.1 |
| HP heater enthalpy (Btu/lb) | 472.4 / 478.1 | 443.8 / 454.1 | 399.6 / 437.3 |
| Air flow (lb/s) | 1225 / 1230 | 961 / 972 | 668 / 653 |
| Fuel flow (lb/s) | 79.8 / 80.1 | 62.6 / 63.3 | 42.1 / 42.4 |

## FORTRAN listing landmarks (for future porting checks)

Approximate line numbers in the OCR text file:

| Content | OCR line ≈ |
|---|---|
| Abstract (model orders) | 32 |
| DYSYS / RK / 0.1 s time step | 1364 |
| Test descriptions V.1–V.7 | 1405–1691 |
| Steady-state Tables V.1–V.3 | 1693–1785 |
| Assumptions (i)–(x) | 799–861 |
| Physical-law templates | 862–962 |
| Turbine–generator equations | 5718–5757 |
| Feed pump / booster pump equations | 5908–5950 |
| `XDUCER` call for `WFT` | 9236 |
| `F(1)` (nfp derivative) | 9964 |
| `SUBROUTINE FWFLOW` | 10648 |
| `SUBROUTINE CRSTAT` | 10194 |
| `SUBROUTINE FPTURB` (`HFTO=1059`) | 11223 |
| `KWFTL=0 / KWFTU=50` | 11821 |

Porting gotchas learned the hard way:

- `1` vs `I` is indistinguishable in the OCR — check every efficiency/anchor
  variable numerically (the `CRSTAT` case: the correct reading was verified
  because the feed-pump torque balance then closes to 4 digits at the p. 288
  initial conditions).
- Sign characters can silently flip in transcription: HXFER's
  `SG=Z1+Z2*(TG1+TGO)` (card PAT11075, printed p. 274) was ported as
  `(tg1-tgo)` and cost ≈10% of fuel/air at every load for two years —
  found Aug 2026 by reading the scan, not the OCR. Cross-check any `±`
  inside a parenthesized sum against the physics (here: mean specific
  heat over the exchanger, consistent with the subroutine's own outlet-
  temperature quadratic).
- The listing's LIMCHK/CHECK calls on state variables act by reference —
  they saturate the stored integrator states themselves (anti-windup),
  not just the values used downstream. A pure-f(t,x) port must reproduce
  this at the stepping level (see `ControlSystem.clampStates`).
- The published initial conditions are excellent consistency oracles: evaluate
  every derivative at them; any |ẋ| far from zero indicates a transcription
  error, not plant physics.
- Small constant inconsistencies exist in the thesis data itself, e.g.
  `N_elec = 376.991` rad/s vs. speed set point `K_ntr = 377.0` — harmless but
  visible as a tiny standing offset.
- The listed turbine-generator inertia `KJTRE = 625000` (data deck line
  ~11462 and parameter table ~7278) appears to be a WR² in lbm·ft², not
  slug·ft²: as listed it gives H ≈ 88 s and cannot reproduce the Test-6
  ride-through of Figure V.10 (the swing pair would lose synchronism);
  divided by g_c it gives H ≈ 2.7 s and matches. The other rotor inertias
  are validated as-listed by the Test-5 speed transients.
- The undamped swing pair integrates stably under RK4 at 0.1 s but **not**
  under explicit Euler — any port that degrades the integration scheme will
  be forced to freeze `N_tr` to survive.
