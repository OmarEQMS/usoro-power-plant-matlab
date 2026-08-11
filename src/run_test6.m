%RUN_TEST6 Thesis Test 6: line frequency drop 60 -> 56 Hz at 77.5% load.
%   Reproduces Usoro (1977) Figure V.10: from t = 10 s the frequency ramps
%   down at 0.8 Hz/s for 5 s. Governor droop drives the valves wide open,
%   but the slowed fans limit air (and hence fuel) flow, so throttle
%   pressure and power settle below their set points (thesis: ~2125 psia,
%   ~537 MW - about 90% of rating). Gas recirculation control is
%   deactivated, as in the thesis run (p. 58). Requires the trimmed 77.5%
%   operating point (run src/tools/trim_op775.m once).

par = model.Parameters();
ctrl = model.ControlSystem(par);
ctrl.gasRecircEnabled = false;
sim = model.Simulator(model.PowerPlant(par), ctrl, ...
                      model.LoadProfile.constant(3.875), ...
                      model.GridProfile.test6());
res = sim.run(model.InitialConditions.at775(), 700);
model.Simulator.plotStandard(res);
