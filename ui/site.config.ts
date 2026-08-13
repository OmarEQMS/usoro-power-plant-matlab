/**
 * Site manifest — single source of truth for sections, page order and
 * titles. The sidebar, pager and cross-link checker are all derived from
 * this file; a page missing here does not exist.
 */

export interface PageDef {
  /** id doubles as content path (ui/content/<id>.md) and output path (<id>.html) */
  id: string;
  title: string;
}

export interface SectionDef {
  id: string;
  title: string;
  pages: PageDef[];
}

export const siteName = 'Usoro Power Plant';

export const sections: SectionDef[] = [
  {
    id: 'basics',
    title: 'Basic Knowledge',
    pages: [
      { id: 'basics/units', title: 'Units and the English engineering system' },
      { id: 'basics/state-variables', title: 'States, systems and ODEs' },
      { id: 'basics/mass-energy-balances', title: 'Mass and energy balances' },
      { id: 'basics/thermo-properties', title: 'Thermodynamic properties of water' },
      { id: 'basics/steam-tables', title: 'Steam tables and polynomial fits' },
      { id: 'basics/fluid-flow', title: 'Pressure-driven flow' },
      { id: 'basics/pumps-fans', title: 'Pumps and fans' },
      { id: 'basics/turbines', title: 'Turbines and expansion work' },
      { id: 'basics/heat-transfer', title: 'Heat transfer' },
      { id: 'basics/rotating-machinery', title: 'Rotating machinery' },
      { id: 'basics/generator-grid', title: 'The generator and the grid' },
      { id: 'basics/control-basics', title: 'Feedback control basics' },
      { id: 'basics/control-practices', title: 'Power-plant control practices' },
      { id: 'basics/numerical-integration', title: 'Numerical integration' },
    ],
  },
  {
    id: 'plant',
    title: 'Power Plant',
    pages: [
      { id: 'plant/overview', title: 'The 600 MW unit at a glance' },
      { id: 'plant/furnace', title: 'Furnace and burners' },
      { id: 'plant/waterwalls-drum', title: 'Waterwalls, drum and circulation' },
      { id: 'plant/superheaters', title: 'Superheaters and spray' },
      { id: 'plant/reheater', title: 'Reheater' },
      { id: 'plant/economizer-airheater', title: 'Economizer and air heater' },
      { id: 'plant/air-gas-path', title: 'Fans and the air/gas path' },
      { id: 'plant/turbine-train', title: 'The turbine train' },
      { id: 'plant/condenser', title: 'Condenser' },
      { id: 'plant/feedwater-train', title: 'The feedwater train' },
      { id: 'plant/generator', title: 'Generator and grid' },
      { id: 'plant/control-room', title: 'The control system at a glance' },
      { id: 'plant/loops-combustion', title: 'Combustion-side control loops' },
      { id: 'plant/loops-steam', title: 'Steam-side control loops' },
      { id: 'plant/loops-turbine', title: 'Turbine control and the governor' },
      { id: 'plant/emergency-tests', title: 'The seven emergency tests' },
      { id: 'plant/changelog', title: 'Model changelog' },
    ],
  },
  {
    id: 'code',
    title: 'Code',
    pages: [
      { id: 'code/tour', title: 'Repository tour' },
      { id: 'code/conventions', title: 'Naming and conventions' },
      { id: 'code/parameters', title: 'Parameters.m' },
      { id: 'code/state-vector', title: 'StateVector.m and the 47 states' },
      { id: 'code/steam-tables', title: 'SteamTables.m' },
      { id: 'code/hydraulics', title: 'Hydraulics.m' },
      { id: 'code/turbomachinery', title: 'Turbomachinery.m' },
      { id: 'code/heat-transfer', title: 'HeatTransfer.m' },
      { id: 'code/vessels', title: 'VesselDynamics.m' },
      { id: 'code/power-plant', title: 'PowerPlant.m' },
      { id: 'code/control-system', title: 'ControlSystem.m' },
      { id: 'code/simulator', title: 'Simulator, profiles and initial conditions' },
      { id: 'code/tests-and-app', title: 'Tests and the dashboard' },
      { id: 'code/equation-to-code', title: 'Equation to code, three walkthroughs' },
    ],
  },
];
