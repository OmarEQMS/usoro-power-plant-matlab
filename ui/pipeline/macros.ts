/**
 * Shared KaTeX macros — recurring symbols of the model, so content pages
 * stay short and consistent. Extend here, never inline per page.
 */
export const macros: Record<string, string> = {
  // g_c, the lbm/lbf conversion constant (32.174 lbm.ft / (lbf.s^2))
  '\\gc': 'g_c',
  // degrees Rankine / Fahrenheit
  '\\degR': '^{\\circ}\\mathrm{R}',
  '\\degF': '^{\\circ}\\mathrm{F}',
  // common units, upright
  '\\unit': '\\;\\mathrm{#1}',
  // mass flow symbol used throughout the thesis (w, not \dot m)
  '\\flow': 'w_{\\mathrm{#1}}',
};
