%RUN_TEST5 Thesis Test 5: 30% step drop in line voltage at 77.5% load.
%   Reproduces Usoro (1977) Figure V.9 (pp. 105-110): at t = 10 s the line
%   voltage steps 4160 V -> 2912 V. The motor-driven auxiliaries (recirc
%   and condensate pumps, FD/ID fans) slow down; the controls compensate
%   and the steam side stays essentially at steady state. Requires the
%   trimmed operating points (run src/tools/trim_operating_points.m once).

par = model.Parameters();
sim = model.Simulator(model.PowerPlant(par), ...
                      model.ControlSystem(par), ...
                      model.LoadProfile.constant(3.875), ...
                      model.GridProfile.test5());
res = sim.run(model.InitialConditions.at775(), 350);
model.Simulator.plotStandard(res);
