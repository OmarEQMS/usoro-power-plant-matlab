# Deprecated — archived pre-OOP implementation

Everything in this folder is **frozen history**: the original flat-script
MATLAB port of Usoro's Digital Model, its documentation, and the tools
that bridge it to the current `src/+model` package. Nothing in `src/`
depends on this folder; it exists as the audit trail behind the current
model's correctness claims.

## Contents

- **`old/`** — the complete legacy flat-script model: entry points
  `pba1_240814bk.m` (original frozen-derivative port), `pba2_rk4.m`
  (RK4 driver), the true derivative `digpte47.m`, init scripts
  (`diginit100/775/50.m`), constant scripts (`const1..3.m`) and ~30
  component functions. **Do not edit** — `validate_against_legacy.m`
  and the kjtre contract depend on these staying as-is (in particular,
  `const1.m` must keep `kjtre=625000` as listed in the thesis deck).
- **`model_old.md`** — the legacy code's documentation: state-vector
  table, module ↔ thesis correspondence, the frozen-speed history
  (why `pba1` hardcoded `nfp`/`ntr` to zero and how RK4 fixed it), and
  the `crstat` isentropic-anchoring fix with its evidence.
- **`tools/gen_parameters.m`** — regenerates `src/+model/Parameters.m`
  from `old/diginit100.m` + `old/const1..3.m`. The legacy scripts are the
  mechanical source of the 306 constants (all values verified against the
  thesis data-deck scan, printed pp. 275–286, Aug 2026); it applies the
  single deliberate deviation, `kjtre = 625000/32.174`.
- **`tools/validate_against_legacy.m`** — the equivalence regression
  harness (below).

## The equivalence proof

The current `src/+model` package was produced by reorganizing the legacy
`digpte47.m` — not re-deriving it — and the equivalence is provable on
demand:

```matlab
run('deprecated/tools/validate_against_legacy.m')   % ~1 min
```

The harness compares `model.Simulator.derivative` against `digpte47(t,x)`
at identical `(t, x)` — 127 sample points covering the canonical ICs, the
trimmed operating points, branch-exercising variants (governor near
closed → the `wtv < kwtv` steam-source switch; large burner tilt → the
gas-recirculation deadband), Test-1 trajectory samples and seeded random
perturbations — plus a 500-step dual-RK4 stepping run. With `kjtre`
restored to the legacy value, all 47 derivative components and the final
RK4 state must match **exactly** (zero difference); with the shipped
`Parameters`, the only allowed difference is `xdot(16)`, scaled by exactly
32.174. It also guards both halves of the kjtre correction contract
(`old/const1.m` keeps 625000; `Parameters` ships 625000/32.174).

Last full pass: Aug 11, 2026 (all checks passed). Historical baseline
(original A/B session): derivative exact at 5 hand-picked branch points,
final state exact after 7000 RK4 steps / 28,000 evaluations; OOP runtime
18.4 s vs legacy 217.3 s for a 700 s Test 1 (~12× — `digpte47` re-runs the
constant scripts on every call).

Run the harness after any edit to `src/+model` or `old/`.
