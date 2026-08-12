/**
 * Central abbreviation glossary — the site-wide rule is that every
 * abbreviation carries its long name: spelled out at first use by the
 * author, and auto-wrapped in <abbr title="..."> everywhere by the
 * markdown pipeline (prose only; code and math are skipped).
 *
 * The build lints prose for all-caps tokens missing from this glossary,
 * so add new entries here as content grows.
 */
export const abbreviations: Record<string, string> = {
  // plant hardware
  FD: 'forced draft',
  ID: 'induced draft',
  HP: 'high pressure',
  IP: 'intermediate pressure',
  LP: 'low pressure',
  FW: 'feedwater',
  FP: 'feed pump',
  // control
  PI: 'proportional–integral',
  LDC: 'load demand computer',
  IC: 'initial condition',
  // math / numerics
  ODE: 'ordinary differential equation',
  RK4: 'fourth-order Runge–Kutta',
  // units
  psia: 'pounds per square inch, absolute',
  Btu: 'British thermal unit',
  lbm: 'pound-mass',
  lbf: 'pound-force',
  MW: 'megawatt',
  // general
  SI: 'Système International — the metric unit system',
  US: 'United States',
  // thesis FORTRAN subroutine names (appear as historical references)
  CRSTAT: 'thesis FORTRAN subroutine: CRossover pipe steam STATe',
  DRSTAT: 'thesis FORTRAN subroutine: DRum saturation STATe',
  DESTAT: 'thesis FORTRAN subroutine: DEaerator saturation STATe',
  SHSTAT: 'thesis FORTRAN subroutine: SuperHeated steam STATe',
  RHSTAT: 'thesis FORTRAN subroutine: ReHeat steam STATe',
  HPEXT: 'thesis FORTRAN subroutine: HP turbine EXTraction flows',
  IPEXT: 'thesis FORTRAN subroutine: IP turbine EXTraction flows',
  LPEXT: 'thesis FORTRAN subroutine: LP turbine EXTraction flows',
  ARFLOW: 'thesis FORTRAN subroutine: AiR-gas FLOW network',
  FWFLOW: 'thesis FORTRAN subroutine: FeedWater FLOW network',
  SHFLOW: 'thesis FORTRAN subroutine: Steam-side orifice FLOW',
  HXFER: 'thesis FORTRAN subroutine: convective Heat transFER',
  FNXFER: 'thesis FORTRAN subroutine: FurNace heat transFER',
  XDUCER: 'thesis FORTRAN subroutine: linear transDUCER',
  CHECK: 'thesis FORTRAN subroutine: clamp a value to arbitrary bounds',
  LIMCHK: 'thesis FORTRAN subroutine: LIMit CHecK — clamp to the 1–5 V rails',
  API: 'application programming interface',
  MB: 'megabyte',
  SYSTAT: 'thesis FORTRAN subroutine: Superheat spraY mix STATe',
  RYSTAT: 'thesis FORTRAN subroutine: Reheat spraY mix STATe',
  CNSTAT: 'thesis FORTRAN subroutine: CoNdenser STATe',
  HPSTAT: 'thesis FORTRAN subroutine: HP turbine exhaust STATe',
  FWSTAT: 'thesis FORTRAN subroutine: FeedWater STATe',
  CWSTAT: 'thesis FORTRAN subroutine: Condensate Water STATe',
  CPSTAT: 'thesis FORTRAN subroutine: Condensate Pump outlet STATe',
  FPSTAT: 'thesis FORTRAN subroutine: Feed Pump outlet STATe',
  RWSTAT: 'thesis FORTRAN subroutine: Recirculation Water STATe',
  LSSTAT: 'thesis FORTRAN subroutine: heater (Low-side) Steam saturation STATe',
  LWSTAT: 'thesis FORTRAN subroutine: heater (Low-side) Water saturation STATe',
  CWFLOW: 'thesis FORTRAN subroutine: Condensate Water FLOW network',
  RWFLOW: 'thesis FORTRAN subroutine: Recirculation Water FLOW network',
  // provenance / tech
  MIT: 'Massachusetts Institute of Technology',
  FORTRAN: 'FORmula TRANslation (1950s programming language)',
  MATLAB: 'MATrix LABoratory (numerical computing environment)',
  DYSYS: 'DYnamic SYstem Simulation, the thesis’ integration program',
  OOP: 'object-oriented programming',
  OCR: 'optical character recognition',
  SVG: 'Scalable Vector Graphics',
  TOC: 'table of contents',
};

/** All-caps tokens the lint should ignore (not abbreviations). */
export const lintIgnore: Set<string> = new Set([
  'II', 'III', 'IV', 'VI', 'VII', 'VIII', // roman numerals (figure/table refs)
  'TODO',
]);
