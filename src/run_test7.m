%RUN_TEST7 Thesis Test 7: loss of one of two FD+ID fan pairs at 100% load.
%   Reproduces Usoro (1977) Figure V.11: after 10 s at 100% load, the
%   number of operating FD and ID fan pairs drops from 2 to 1 with the
%   load command left at 100% (no Unit Run-Back). The surviving pair
%   cannot meet the air demand: the air control saturates at 5 V, throttle
%   pressure falls (thesis: settles ~1700 psia) and the maximum deliverable
%   power drops (thesis: ~70%, 420 MW). The surviving FD fan slows under
%   the extra duty; the ID fan speeds up slightly. Gas recirculation
%   control is deactivated, as in the thesis run (p. 60).
%
%   The fan count is a plant configuration constant (knfd/knid), so the
%   step is simulated as two phases stitched at t = 10 s.

par = model.Parameters();
ctrl = model.ControlSystem(par);
ctrl.gasRecircEnabled = false;
x0 = model.InitialConditions.at100();
holdLoad = model.LoadProfile.constant(5.0);

% phase 1: 10 s steady with both fan pairs
sim1 = model.Simulator(model.PowerPlant(par), ctrl, holdLoad);
r1 = sim1.run(x0, 10);

% phase 2: one pair remaining
par2 = par;
par2.knfd = 1.0;
par2.knid = 1.0;
ctrl2 = model.ControlSystem(par2);
ctrl2.gasRecircEnabled = false;
sim2 = model.Simulator(model.PowerPlant(par2), ctrl2, holdLoad);
r2 = sim2.run(r1.X(end, :)', 690);

% stitch the two phases (shift phase-2 time by 10 s)
res.log = [r1.log; r2.log(2:end, :) + [10, zeros(1, size(r2.log, 2) - 1)]];
res.logNames = r1.logNames;
res.t = [r1.t; r2.t(2:end) + 10];
res.X = [r1.X; r2.X(2:end, :)];
res.stateNames = r1.stateNames;
model.Simulator.plotStandard(res);
