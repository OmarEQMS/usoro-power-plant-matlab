function trim_operating_points
%TRIM_OPERATING_POINTS Generate the 77.5% and 50% operating points.
%   Writes +model/ic775.mat and +model/ic50.mat by trimming the current
%   model (crstat fix, all 47 states live). Each point is reached by
%   ramping down from the previous one at the thesis 15%/min rate, then:
%     1. settling 1300 s at constant ldc,
%     2. settling a further 300 s with temporary damping added to the
%        turbine-generator swing pair (the swing mode is undamped, so it
%        never settles by itself; damping does not move the equilibrium),
%     3. pinning the swing pair exactly: ntr = nelec,
%        delta = asin(mwtro/2Kmwr).

thisdir = fileparts(mfilename('fullpath'));   % .../src/tools
srcdir  = fileparts(thisdir);                 % .../src
addpath(srcdir);

par = model.Parameters();
plant = model.PowerPlant(par);
ctrl = model.ControlSystem(par);

% 100% -> 77.5% (thesis Test 1 ramp), settle, pin
sim = model.Simulator(plant, ctrl, model.LoadProfile.test1());
r = sim.run(model.InitialConditions.at100(), 700);
x775 = settleAndPin(plant, ctrl, par, r.X(end, :)', 3.875); %#ok<NASGU>
reportResiduals(plant, ctrl, par, x775, 3.875, '77.5%');
save(fullfile(srcdir, '+model', 'ic775.mat'), 'x775');
fprintf('wrote %s\n', fullfile(srcdir, '+model', 'ic775.mat'));

% 77.5% -> 50% (thesis Test 2 ramp), settle, pin
sim = model.Simulator(plant, ctrl, model.LoadProfile.test2());
r = sim.run(x775, 700);
x50 = settleAndPin(plant, ctrl, par, r.X(end, :)', 2.5); %#ok<NASGU>
reportResiduals(plant, ctrl, par, x50, 2.5, '50%');
save(fullfile(srcdir, '+model', 'ic50.mat'), 'x50');
fprintf('wrote %s\n', fullfile(srcdir, '+model', 'ic50.mat'));
end

function x = settleAndPin(plant, ctrl, par, x, ldc)
sim = model.Simulator(plant, ctrl, model.LoadProfile.constant(ldc));
r = sim.run(x, 1300);
x = r.X(end, :)';
% damped settling of the swing pair (zeta ~ 0.5 at the swing mode)
kd = 10.0;
dampVec = zeros(47, 1);
dampVec(model.StateVector.NTR) = 1;
f = @(t, xx) sim.derivative(t, xx) - kd*(xx(model.StateVector.NTR) - par.nelec)*dampVec;
h = sim.Ts;
for k = 1:round(300/h)
    tk = (k - 1)*h;
    k1 = f(tk, x);
    k2 = f(tk + h/2, x + (h/2)*k1);
    k3 = f(tk + h/2, x + (h/2)*k2);
    k4 = f(tk + h, x + h*k3);
    x = x + (h/6)*(k1 + 2*k2 + 2*k3 + k4);
end
% pin the swing pair on its exact equilibrium
x(model.StateVector.NTR) = par.nelec;
[~, sig] = sim.derivative(0, x);
x(model.StateVector.DELTA) = asin(sig.mwtro/(par.kn2*par.kmwr));
end

function reportResiduals(plant, ctrl, par, x, ldc, label)
sim = model.Simulator(plant, ctrl, model.LoadProfile.constant(ldc));
xdot = sim.derivative(0, x);
[worst, order] = sort(abs(xdot), 'descend');
names = model.StateVector.names();
fprintf('largest trim residuals |xdot| at %s:\n', label);
for i = 1:5
    fprintf('  %-6s %.3e\n', names{order(i)}, worst(i));
end
end
