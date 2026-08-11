%RUN_TEST4 Thesis Test 4: load ramp 77.5% -> 100% at 15%/min.
%   Reproduces Usoro (1977) Figure V.7: after 10 s steady, ldc ramps
%   3.875 -> 5 over 90 s (465 -> 600 MW). The thesis calls this run only
%   "fairly well behaved": the plant is near maximum capability, several
%   control signals saturate and the power output does not follow the
%   demand exactly. Requires the trimmed operating points (run
%   src/tools/trim_operating_points.m once).

par = model.Parameters();
sim = model.Simulator(model.PowerPlant(par), ...
                      model.ControlSystem(par), ...
                      model.LoadProfile.test4());
res = sim.run(model.InitialConditions.at775(), 700);
model.Simulator.plotStandard(res);
