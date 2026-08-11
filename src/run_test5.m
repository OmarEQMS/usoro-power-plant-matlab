%RUN_TEST5 Thesis Test 5: 30% step drop in line voltage at 77.5% load.
%   Reproduces Usoro (1977) Figure V.9 (pp. 105-110): at t = 10 s the line
%   voltage steps 4160 V -> 2912 V. The motor-driven auxiliaries (recirc
%   and condensate pumps, FD/ID fans) slow down; the controls compensate
%   and the steam side stays essentially at steady state. Requires the
%   trimmed 77.5% operating point (run src/tools/trim_op775.m once).

par = usoro.Parameters();
sim = usoro.Simulator(usoro.PowerPlant(par), ...
                      usoro.ControlSystem(par), ...
                      usoro.LoadProfile.constant(3.875), ...
                      usoro.GridProfile.test5());
res = sim.run(usoro.InitialConditions.at775(), 350);
usoro.Simulator.plotStandard(res);
