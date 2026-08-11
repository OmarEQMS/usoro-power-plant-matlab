%RUN_TEST2 Thesis Test 2: load ramp 77.5% -> 50% at 15%/min.
%   Reproduces Usoro (1977) Figure V.3: after 10 s steady, ldc ramps
%   3.875 -> 2.5 over 110 s (465 -> 300 MW). Note the main steam and
%   reheat temperature set points change near 50% load (scheduled on whp).
%   Requires the trimmed operating points (run
%   src/tools/trim_operating_points.m once).

par = model.Parameters();
sim = model.Simulator(model.PowerPlant(par), ...
                      model.ControlSystem(par), ...
                      model.LoadProfile.test2());
res = sim.run(model.InitialConditions.at775(), 700);
model.Simulator.plotStandard(res);
