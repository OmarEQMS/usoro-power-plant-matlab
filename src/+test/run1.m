function res = run1()
%RUN1 Thesis Test 1: load ramp 100% -> 77.5% at 15%/min.
%   res = test.run1() reproduces Usoro (1977) Figure V.1 (pp. 65-70),
%   plots the six standard figures and returns the simulation results
%   (see model.Simulator.run). Run with src/ on the MATLAB path.

par = model.Parameters();
sim = model.Simulator(model.PowerPlant(par), ...
                      model.ControlSystem(par), ...
                      model.LoadProfile.test1());
res = sim.run(model.InitialConditions.at100(), 700);
model.Simulator.plotStandard(res);
end
