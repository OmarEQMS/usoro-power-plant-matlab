function res = run4()
%RUN4 Thesis Test 4: load ramp 77.5% -> 100% at 15%/min.
%   res = test.run4() reproduces Usoro (1977) Figure V.7: after 10 s
%   steady, ldc ramps 3.875 -> 5 over 90 s (465 -> 600 MW). The thesis
%   calls this run only "fairly well behaved" (signals saturate). This
%   model climbs to the rated point and settles there (600.3 MW,
%   2415.0 psia, main steam ~1109 lb/s - Table V.1's 100% state; uses
%   the documented fan-curve calibration, see docs/model.md "Known
%   quantitative offsets"). Requires the trimmed operating points (run
%   src/tools/trim_operating_points.m once).

par = model.Parameters();
sim = model.Simulator(model.PowerPlant(par), ...
                      model.ControlSystem(par), ...
                      model.LoadProfile.test4());
res = sim.run(model.InitialConditions.at775(), 700);
model.Simulator.plotStandard(res);
end
