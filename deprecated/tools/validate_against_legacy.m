function validate_against_legacy(opts)
%VALIDATE_AGAINST_LEGACY Regression proof: OOP derivative == legacy digpte47.
%   Permanent harness for the bit-for-bit equivalence claim of
%   deprecated/README.md. It compares model.Simulator.derivative (the
%   current model in src/+model) against the archived legacy
%   deprecated/old/digpte47 at identical (t, x) and errors out on the
%   first discrepancy:
%
%     1. With kjtre restored to the legacy as-listed 625000, all 47
%        derivative components must match EXACTLY (zero difference) at
%        every sample point, and a dual-RK4 stepping run must land on a
%        bit-for-bit identical state.
%     2. With the shipped Parameters (kjtre = 625000/32.174), the only
%        allowed difference is xdot(16), equal to 32.174 x the legacy value
%        up to a few eps of floating-point rounding.
%
%   Sample points: the canonical 100% IC, the trimmed 77.5%/50% points,
%   two branch-exercising variants (governor demand near closed -> the
%   wtv < kwtv steam-source switch; large burner tilt -> the
%   gas-recirculation deadband), plus states sampled along a Test 1 ramp
%   trajectory and small random perturbations of each sample
%   (deterministic seed).
%
%   Also guards both halves of the kjtre correction contract:
%   deprecated/old/const1.m must still list 625000 (uncorrected) and
%   model.Parameters must ship 625000/32.174 — a "fix" on either side
%   would silently double- or un-apply the correction.
%
%   Runtime ~30-60 s, dominated by the legacy digpte47 evaluations (each
%   one re-runs the constant scripts). Options:
%     rk4Seconds   dual-RK4 stepping window, 0 skips it   (default 50)
%     trajSeconds  Test 1 trajectory to draw samples from (default 300)
%     sampleEvery  spacing of trajectory samples [s]      (default 5)

arguments
    opts.rk4Seconds  (1,1) double {mustBeNonnegative} = 50
    opts.trajSeconds (1,1) double {mustBePositive}    = 300
    opts.sampleEvery (1,1) double {mustBePositive}    = 5
end

thisdir = fileparts(mfilename('fullpath'));   % .../deprecated/tools
depdir  = fileparts(thisdir);                 % .../deprecated
srcdir  = fullfile(fileparts(depdir), 'src'); % .../src
prevPath = addpath(srcdir, fullfile(depdir, 'old'));
restorePath = onCleanup(@() path(prevPath)); %#ok<NASGU>

% --- kjtre correction contract (guards against double-correction) -------
assert(legacyKjtre() == 625000, ...
    ['deprecated/old/const1.m no longer lists kjtre=625000. The legacy ' ...
     'value must stay as-listed in the thesis deck; ' ...
     'deprecated/tools/gen_parameters.m applies the /32.174 units ' ...
     'correction (see docs/model.md).']);
par = model.Parameters();
assert(par.kjtre == 625000/32.174, ...
    ['model.Parameters.kjtre is not 625000/32.174; the kjtre units ' ...
     'correction was lost. Re-run deprecated/tools/gen_parameters.m.']);
fprintf('kjtre contract: legacy 625000, Parameters 625000/32.174 ... OK\n');

% Twin model with the legacy (uncorrected) kjtre: must match digpte47
% exactly. digpte47 hardcodes the Test 1 ldc ramp and the nominal grid,
% so the simulators must use the same profiles.
parTwin = par;
parTwin.kjtre = 625000;
simTwin = model.Simulator(model.PowerPlant(parTwin), ...
    model.ControlSystem(parTwin), model.LoadProfile.test1());
simCorr = model.Simulator(model.PowerPlant(par), ...
    model.ControlSystem(par), model.LoadProfile.test1());

% --- sample set ----------------------------------------------------------
sv = model.StateVector;
x100 = model.InitialConditions.at100();
tmp = load(fullfile(srcdir, '+model', 'ic775.mat'));
x775 = tmp.x775;
tmp = load(fullfile(srcdir, '+model', 'ic50.mat'));
x50 = tmp.x50;
xGov = x100;  xGov(sv.CACVD)  = 1.2;   % governor near closed: wtv < kwtv
xTilt = x100; xTilt(sv.CXGGD) = 4.8;   % large tilt: gas-recirc deadband
pts = {0, x100; 700, x775; 700, x50; 0, xGov; 0, xTilt};

res = simTwin.run(x100, opts.trajSeconds);
stride = max(1, round(opts.sampleEvery/simTwin.Ts));
rng(20260812, 'twister');
for k = 1:stride:size(res.X, 1)
    xk = res.X(k, :)';
    pts(end+1, :) = {res.t(k), xk};                            %#ok<AGROW>
    pts(end+1, :) = {res.t(k), xk.*(1 + 1e-3*randn(47, 1))};   %#ok<AGROW>
end

% --- pointwise derivative comparison -------------------------------------
names = model.StateVector.names();
others = setdiff(1:47, sv.NTR);
maxRel16 = 0;
for i = 1:size(pts, 1)
    t = pts{i, 1};
    x = pts{i, 2};
    xdLegacy = digpte47(t, x);
    xdTwin = simTwin.derivative(t, x);
    bad = find(xdTwin ~= xdLegacy);
    if ~isempty(bad)
        error(['legacy-kjtre twin differs from digpte47 at point %d ' ...
            '(t=%g): xdot(%d) [%s] OOP %.17g vs legacy %.17g'], ...
            i, t, bad(1), names{bad(1)}, xdTwin(bad(1)), xdLegacy(bad(1)));
    end
    xdCorr = simCorr.derivative(t, x);
    bad = others(xdCorr(others) ~= xdLegacy(others));
    if ~isempty(bad)
        error(['corrected model differs from digpte47 outside xdot(16) ' ...
            'at point %d (t=%g): xdot(%d) [%s] OOP %.17g vs legacy %.17g'], ...
            i, t, bad(1), names{bad(1)}, xdCorr(bad(1)), xdLegacy(bad(1)));
    end
    want16 = 32.174*xdLegacy(sv.NTR);
    rel16 = abs(xdCorr(sv.NTR) - want16)/max(1, abs(want16));
    maxRel16 = max(maxRel16, rel16);
end
assert(maxRel16 <= 1e-14, ...
    'xdot(16) scaling is not the documented 32.174 (max rel. err %.3g)', ...
    maxRel16);
fprintf(['pointwise: %d points x 47 components exact; xdot(16) scaling ' ...
    '32.174 (max rel. err %.2g) ... OK\n'], size(pts, 1), maxRel16);

% --- dual-RK4 stepping (legacy-kjtre twin vs digpte47) --------------------
if opts.rk4Seconds > 0
    h = simTwin.Ts;
    nSteps = round(opts.rk4Seconds/h);
    xA = x100;
    xB = x100;
    for k = 1:nSteps
        tk = (k - 1)*h;
        xA = simTwin.step(tk, xA);
        k1 = digpte47(tk, xB);
        k2 = digpte47(tk + h/2, xB + (h/2)*k1);
        k3 = digpte47(tk + h/2, xB + (h/2)*k2);
        k4 = digpte47(tk + h, xB + h*k3);
        xB = xB + (h/6)*(k1 + 2*k2 + 2*k3 + k4);
    end
    bad = find(xA ~= xB);
    if ~isempty(bad)
        error(['dual-RK4 states diverge after %d steps: x(%d) [%s] ' ...
            'OOP %.17g vs legacy %.17g'], ...
            nSteps, bad(1), names{bad(1)}, xA(bad(1)), xB(bad(1)));
    end
    fprintf('dual RK4: %d steps (%g s), final state bit-for-bit ... OK\n', ...
        nSteps, opts.rk4Seconds);
end

fprintf('validate_against_legacy: ALL CHECKS PASSED\n');
end

function v = legacyKjtre()
%LEGACYKJTRE kjtre exactly as deprecated/old/const1.m sets it (script runs
%   in this function's workspace, so nothing leaks to the caller).
const1
v = kjtre;
end
