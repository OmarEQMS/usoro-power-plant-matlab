classdef Simulator < handle
%SIMULATOR Fixed-step RK4 integration of the 47-state Digital Model.
%   Combines a model.PowerPlant, a model.ControlSystem and a
%   model.LoadProfile into the full state derivative f(t,x) and advances it
%   with the classic 4th-order Runge-Kutta scheme at Ts = 0.1 s - the same
%   integration the thesis used (DYSYS, p. 49). RK4 is stable for the
%   undamped turbine-generator swing pair; explicit Euler is not (see
%   docs/model_old.md for that history).
%
%   Example:
%     par = model.Parameters();
%     sim = model.Simulator(model.PowerPlant(par), ...
%                           model.ControlSystem(par), ...
%                           model.LoadProfile.test1());
%     res = sim.run(model.InitialConditions.at100(), 700);

    properties (SetAccess = immutable)
        plant   model.PowerPlant
        control model.ControlSystem
        profile model.LoadProfile
        grid    model.GridProfile
    end

    properties
        Ts          (1,1) double {mustBePositive} = 0.1  % integration step [s]
        logInterval (1,1) double {mustBePositive} = 1.0  % signal-log spacing [s]
    end

    methods
        function obj = Simulator(plant, control, profile, grid)
            arguments
                plant   (1,1) model.PowerPlant
                control (1,1) model.ControlSystem
                profile (1,1) model.LoadProfile = model.LoadProfile.constant(5.0)
                grid    (1,1) model.GridProfile = model.GridProfile.nominal()
            end
            obj.plant = plant;
            obj.control = control;
            obj.profile = profile;
            obj.grid = grid;
        end

        function [xdot, sig, u] = derivative(obj, t, x)
            %DERIVATIVE Full 47-state derivative f(t,x); also returns the
            %   plant signal struct and actuator commands for logging.
            s = model.StateVector.unpack(x);
            u = obj.control.actuatorCommands(s);
            g = struct('nelec', obj.grid.frequency(t), 'velec', obj.grid.voltage(t));
            [xdot, sig] = obj.plant.evaluate(s, u, g);
            xdot = xdot + obj.control.derivatives(s, u, sig, obj.profile.demand(t));
        end

        function res = run(obj, x0, tEnd)
            %RUN Integrate from x0 over [0, tEnd]; returns trajectories and
            %   the standard signal log (same columns as the legacy xx2).
            arguments
                obj
                x0   (47,1) double
                tEnd (1,1) double {mustBePositive}
            end
            h = obj.Ts;
            nSteps = round(tEnd/h);
            t = (0:nSteps)'*h;
            X = zeros(nSteps + 1, 47);
            X(1, :) = x0';
            nLog = floor(tEnd/obj.logInterval) + 1;
            logRows = zeros(nLog, 25);
            iLog = 0;
            nextLog = 0;
            x = x0;
            for k = 1:nSteps + 1
                tk = t(k);
                [k1, sig] = obj.derivative(tk, x);
                if tk >= nextLog && iLog < nLog
                    iLog = iLog + 1;
                    logRows(iLog, :) = obj.logRow(tk, x, sig);
                    nextLog = nextLog + obj.logInterval;
                end
                if k == nSteps + 1
                    break
                end
                k2 = obj.derivative(tk + h/2, x + (h/2)*k1);
                k3 = obj.derivative(tk + h/2, x + (h/2)*k2);
                k4 = obj.derivative(tk + h, x + h*k3);
                x = x + (h/6)*(k1 + 2*k2 + 2*k3 + k4);
                X(k + 1, :) = x';
            end
            res.t = t;
            res.X = X;
            res.stateNames = model.StateVector.names();
            res.log = logRows(1:iLog, :);
            res.logNames = model.Simulator.logNames();
        end
    end

    methods (Static)
        function names = logNames()
            %LOGNAMES Column names of res.log (matches the legacy xx2).
            names = {'t','ntr','mwo','psso','whp','c3md','cacvd','cfld', ...
                'card','vdrw','vdew','cfwd','cdwd','hsso','hrho','csyd', ...
                'cxggd','nfp','cgrd','cfnd','twwm','nfd','nid','nrp','ncp'};
        end

        function plotStandard(res)
            %PLOTSTANDARD The six standard 2x2 figures (thesis Fig. V.x layout).
            groups = {{'ntr','mwo','psso','whp'}, ...
                      {'c3md','cacvd','cfld','card'}, ...
                      {'vdrw','vdew','cfwd','cdwd'}, ...
                      {'hsso','hrho','csyd','cxggd'}, ...
                      {'nfp','cgrd','cfnd','twwm'}, ...
                      {'nfd','nid','nrp','ncp'}};
            t = res.log(:, 1);
            for g = 1:numel(groups)
                figure
                for i = 1:4
                    ax = subplot(2, 2, i);
                    plot(ax, t, res.log(:, strcmp(res.logNames, groups{g}{i})));
                    title(ax, groups{g}{i});
                end
            end
        end
    end

    methods (Access = private)
        function row = logRow(~, tk, x, sig)
            sv = model.StateVector;
            row = [tk, x(sv.NTR), sig.mwo, sig.psso, sig.whp, x(sv.C3MD), ...
                x(sv.CACVD), x(sv.CFLD), x(sv.CARD), x(sv.VDRW), x(sv.VDEW), ...
                x(sv.CFWD), x(sv.CDWD), x(sv.HSSO), x(sv.HRHO), x(sv.CSYD), ...
                x(sv.CXGGD), x(sv.NFP), x(sv.CGRD), x(sv.CFND), x(sv.TWWM), ...
                x(sv.NFD), x(sv.NID), x(sv.NRP), x(sv.NCP)];
        end
    end
end
