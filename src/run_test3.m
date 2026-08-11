%RUN_TEST3 Thesis Test 3: load ramp 50% -> 77.5% at 15%/min.
%   Reproduces Usoro (1977) Figure V.5: after 10 s steady, ldc ramps
%   2.5 -> 3.875 over 110 s (300 -> 465 MW). The thesis notes the system
%   finds load increases harder than decreases (~1% overshoot). Requires
%   the trimmed operating points (run src/tools/trim_operating_points.m
%   once).

par = model.Parameters();
sim = model.Simulator(model.PowerPlant(par), ...
                      model.ControlSystem(par), ...
                      model.LoadProfile.test3());
res = sim.run(model.InitialConditions.at50(), 700);
model.Simulator.plotStandard(res);
