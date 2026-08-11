function trim_op775
%TRIM_OP775 Generate the 77.5%-load operating point (+model/ic775.mat).
%   Trims the current model (crstat fix, all 47 states live):
%     1. thesis Test 1 ramp 100% -> 77.5% (700 s),
%     2. settle 1300 s at constant ldc = 3.875,
%     3. settle a further 300 s with temporary damping added to the
%        turbine-generator swing pair (the model's swing mode is undamped,
%        so it never settles by itself; damping does not move the
%        equilibrium),
%     4. pin the swing pair exactly: ntr = nelec, delta = asin(mwtro/2Kmwr).
%   The legacy 77.5% sets in src/old are frozen-era artifacts and are not
%   equilibria of this model.

thisdir = fileparts(mfilename('fullpath'));   % .../src/tools
srcdir  = fileparts(thisdir);                 % .../src
addpath(srcdir);

par = model.Parameters();
plant = model.PowerPlant(par);
ctrl = model.ControlSystem(par);

sim1 = model.Simulator(plant, ctrl, model.LoadProfile.test1());
r1 = sim1.run(model.InitialConditions.at100(), 700);

sim2 = model.Simulator(plant, ctrl, model.LoadProfile.constant(3.875));
r2 = sim2.run(r1.X(end, :)', 1300);

% damped settling of the swing pair (zeta ~ 0.55 at the ~1.8 rad/s mode)
kd = 2.0;
dampVec = zeros(47, 1);
dampVec(model.StateVector.NTR) = 1;
f = @(t, x) sim2.derivative(t, x) - kd*(x(model.StateVector.NTR) - par.nelec)*dampVec;
h = sim2.Ts;
x = r2.X(end, :)';
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
[~, sig] = sim2.derivative(0, x);
x(model.StateVector.DELTA) = asin(sig.mwtro/(par.kn2*par.kmwr));
x775 = x;

xdot = sim2.derivative(0, x775);
[worst, order] = sort(abs(xdot), 'descend');
names = model.StateVector.names();
fprintf('largest trim residuals |xdot|:\n');
for i = 1:5
    fprintf('  %-6s %.3e\n', names{order(i)}, worst(i));
end

save(fullfile(srcdir, '+model', 'ic775.mat'), 'x775');
fprintf('wrote %s\n', fullfile(srcdir, '+model', 'ic775.mat'));
end
