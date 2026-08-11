%RUN_TEST1 Thesis Test 1 with the OOP model: load ramp 100% -> 77.5%.
%   Reproduces Usoro (1977) Figure V.1 (pp. 65-70). Run with src/ on the
%   MATLAB path. See docs/model.md for the architecture.

par = model.Parameters();
sim = model.Simulator(model.PowerPlant(par), ...
                      model.ControlSystem(par), ...
                      model.LoadProfile.test1());
res = sim.run(model.InitialConditions.at100(), 700);
model.Simulator.plotStandard(res);
