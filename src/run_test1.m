%RUN_TEST1 Thesis Test 1 with the OOP model: load ramp 100% -> 77.5%.
%   Reproduces Usoro (1977) Figure V.1 (pp. 65-70). Run with src/ on the
%   MATLAB path. See docs/model_oop.md for the architecture.

par = usoro.Parameters();
sim = usoro.Simulator(usoro.PowerPlant(par), ...
                      usoro.ControlSystem(par), ...
                      usoro.LoadProfile.test1());
res = sim.run(usoro.InitialConditions.at100(), 700);
usoro.Simulator.plotStandard(res);
