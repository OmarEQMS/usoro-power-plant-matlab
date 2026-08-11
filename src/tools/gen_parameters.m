function gen_parameters
%GEN_PARAMETERS Regenerate src/+usoro/Parameters.m from the legacy scripts.
%   Runs the legacy constant scripts (src/old: diginit100, const1..const3)
%   and emits every plant/control constant as a literal property default of
%   usoro.Parameters. Simulation setup, state values, scenario inputs and
%   logging variables are excluded. Re-run this tool whenever the legacy
%   constant scripts change.

thisdir = fileparts(mfilename('fullpath'));   % .../src/tools
srcdir  = fileparts(thisdir);                 % .../src
addpath(fullfile(srcdir, 'old'));

diginit100
const1
const2
const3

names = who;
% not constants: sim setup, initial-state data, state names, scenario and
% derivative-precomputation variables from the legacy scripts
skip = {'thisdir','srcdir','names','ans', ...
    'x0','xx','xx2','x00','tprint','Ts','samples','mat_model','t', ...
    'nfp','hhho','heco','vdrw','rdrs','nrp','twwm','rpso','hpso','rsso', ...
    'hsso','rsco','rrho','hrho','rcro','ntr','ncp','hlho','vdew','rdes', ...
    'nfd','nid','c3md','c5ar','c5fl','c3fn','c2gr','c2ft','c3fv','c7fv', ...
    'c3dv','c8dv','c5rh','c5sy','card','cfld','cfnd','cgrd','cftd','cfwd', ...
    'cdwd','cxggd','csyd','c2tr','c4tr','cacvd','delta', ...
    'ldc','jcount','tstep','catvd','caivd', ...
    'c2dv0','cp1st0','ctrho0','cxgg0','c2dv','cp1st','ctrho','cxgg', ...
    'fc2dv','fcp1st','fctrho','fcxgg'};
names = setdiff(names, skip);

outfile = fullfile(srcdir, '+usoro', 'Parameters.m');
fid = fopen(outfile, 'w');
assert(fid > 0, 'cannot open %s', outfile);
cleaner = onCleanup(@() fclose(fid));

fprintf(fid, 'classdef Parameters\n');
fprintf(fid, '%%PARAMETERS Plant and control-system constants of the Usoro Digital Model.\n');
fprintf(fid, '%%   GENERATED FILE - do not edit by hand. Regenerate with src/tools/gen_parameters.m,\n');
fprintf(fid, '%%   which extracts the values from the legacy scripts in src/old\n');
fprintf(fid, '%%   (diginit100.m, const1.m, const2.m, const3.m).\n');
fprintf(fid, '%%\n');
fprintf(fid, '%%   Names follow the thesis symbols (Usoro 1977, Appendix A/C):\n');
fprintf(fid, '%%   k*   gains, fits and physical constants     kv*  fill volumes\n');
fprintf(fid, '%%   km*m metal masses      ks*m specific heats  kj*  rotor inertias\n');
fprintf(fid, '%%   ku*  heat-transfer coefficients             kf*  friction factors\n');
fprintf(fid, '%%   kc*  controller gains  ktc* controller time constants\n');
fprintf(fid, '%%   kn*/km(digit) numeric literals from the FORTRAN data deck\n');
fprintf(fid, '\n    properties\n');
for i = 1:numel(names)
    v = eval(names{i}); %#ok<*EVLDOT>
    assert(isscalar(v) && isnumeric(v), 'unexpected non-scalar constant %s', names{i});
    fprintf(fid, '        %s = %.17g;\n', names{i}, v);
end
fprintf(fid, '    end\nend\n');
fprintf('wrote %s with %d constants\n', outfile, numel(names));
end
