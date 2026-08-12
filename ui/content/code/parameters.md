---
description: The generated constants class — 306 thesis data-deck values as read-only properties, one deliberate correction, and how to run parameter studies against it.
sourceFile: src/+model/Parameters.m
---

# Parameters.m

Every constant the model uses — every gain, volume, inertia, fit
coefficient and transducer range — lives in one value class as a
property with a literal default. No configuration files, no magic
numbers buried in equations: 306 named constants, all from the thesis
data deck, all documented by the
[naming scheme](@code/conventions).

::: why
A model is its equations *times its numbers*. This project has caught
real bugs on both sides — and the numbers side (a units misreading, an
OCR-garbled coefficient) is why `Parameters.m` is generated
mechanically and verified against the thesis scan rather than typed by
hand. Trust in this file is trust in every result.
:::

## A generated file

The header says it plainly: *generated file — do not edit by hand*.
306 hand-typed constants would be a typo lottery; instead the class is
emitted by a tool from the archived transcription of the thesis' three
`CONST` subroutines, and every value was verified against the scanned
data-deck pages (printed pp. 275–286) in August 2026. Treat it as
read-only data with a paper trail.

```matlab
properties
    kjtre = 625000/32.174; % units correction, see docs/model.md
    khfl = 18200;
    kcvreg = 0.050000000000000003;
    ...
end
```

(The long decimals are exact `%.17g` round-trips of the deck values —
generation artifacts, not precision claims.)

## The one deliberate deviation

`kjtre` is the only constant that differs from the deck as printed:
the listed `625000` is vendor-style $WR^2$ in lbm·ft², not a dynamic
inertia, and is divided by $g_c$ on generation. The full story — the
impossible 88-second inertia constant, the Test 6 pole slip that
settled it — is on the [units page](@basics/units); the policy is
one line: *the correction is applied exactly once, here.*

## Reading it

Three habits make the file navigable:

- **Go by family.** Looking for a time constant? It starts `ktc`. A
  transducer range? Its `l/u` pair sits together alphabetically. The
  [family table](@code/conventions) is the index.
- **Trust the tooltips.** On this site, hover any constant in a code
  span for its meaning; in MATLAB, the header comment names the deck
  sections.
- **Counts as sanity checks:** 6 inertias (`kj*`), 10+ volumes
  (`kv*`), 8 friction coefficients (`kf*`), ~40 controller gains and
  time constants (`kc*`/`ktc*`) — if a family looks bigger or smaller
  than the plant warrants, something is misfiled.

## Parameter studies

`Parameters` is a **value class**: copies are independent, so studies
are three lines —

```matlab
par2 = par;                    % independent copy
par2.kjtre = 2*par.kjtre;      % a heavier rotor
sim2 = model.Simulator(model.PowerPlant(par2), model.ControlSystem(par2));
```

— and the original `par` is untouched. Both the plant and the control
system take the parameters at construction; build both from the *same*
copy or the physics and the controllers will disagree about the plant
they inhabit.

::: caution
Not every number in the model lives here. Subroutine-local fit
coefficients — pump curves, steam-table polynomials — stay inside
their methods, [exactly as the thesis kept them
subroutine-local](@code/steam-tables): they are curve-fit internals,
not tunable plant parameters. If you cannot find a coefficient in
`Parameters`, look in the method that uses it.
:::

::: code-map Where this page lives in the code
| Concept | Code | Where |
|---|---|---|
| the constants | `model.Parameters` properties | `src/+model/Parameters.m` |
| the kjtre correction | `kjtre = 625000/32.174` | `src/+model/Parameters.m` |
| generation tool (archived) | `gen_parameters.m` | `deprecated/tools/` |
| local fit coefficients | e.g. `k1fp…k6fp` | `Hydraulics.feedwater` etc. |
:::

Next: [StateVector.m and the 47 states](@code/state-vector) — the
model's one true index.
