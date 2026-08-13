classdef PlantApp < handle
%PLANTAPP Interactive dashboard for the Usoro 47th-order plant model.
%   app = PlantApp;   % with src/ on the MATLAB path
%
%   A schematic of the plant with clickable components: clicking a block
%   opens a window with live charts of that component's key variables.
%   The toolbar selects the scenario (thesis Tests 1-7 or a steady hold),
%   plays/pauses/resets the simulation, and sets the simulation speed and
%   run time (the run-time selector can extend a finished run in place).
%   Integration is the same RK4/0.1 s scheme as model.Simulator.run
%   (driven incrementally through model.Simulator.step).

    properties (SetAccess = private)
        Fig             matlab.ui.Figure
        Par             model.Parameters
    end

    properties (Access = private)
        Ax                          % diagram axes
        StatusLabel
        ScenarioDD
        SpeedDD
        DurationDD
        Timer
        Running (1,1) logical = false

        % scenario state
        Sims            cell = {}
        SwitchTimes     double = []
        Phase (1,1) double = 1
        X0              double
        TEnd (1,1) double = 700
        T (1,1) double = 0
        X               double
        Idx (1,1) double = 1

        % signal buffer
        Fields          cell = {}   % master signal names
        Src             double = [] % 1=state struct, 2=sig, 3=u
        TBuf            double = []
        Buf             double = []

        Charts                      % containers.Map: component id -> chart struct
        CompDefs        struct      % component registry
    end

    methods
        function obj = PlantApp()
            obj.Par = model.Parameters();
            obj.Charts = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.CompDefs = obj.componentRegistry();
            obj.buildUi();
            obj.Timer = timer('ExecutionMode', 'fixedSpacing', 'Period', 0.08, ...
                'TimerFcn', @(~, ~) obj.onTick());
            obj.loadScenario(obj.ScenarioDD.Value);
        end

        function delete(obj)
            try %#ok<TRYNC>
                stop(obj.Timer);
                delete(obj.Timer);
            end
            for k = keys(obj.Charts)
                c = obj.Charts(k{1});
                if isvalid(c.fig)
                    delete(c.fig);
                end
            end
            if ~isempty(obj.Fig) && isvalid(obj.Fig)
                delete(obj.Fig);
            end
        end

        function stepChunk(obj, n)
            %STEPCHUNK Advance n RK4 steps and refresh the UI once.
            for i = 1:n
                if obj.T > obj.TEnd - 1e-9
                    obj.Running = false;
                    stop(obj.Timer);
                    break
                end
                while obj.Phase < numel(obj.Sims) && obj.T >= obj.SwitchTimes(obj.Phase) - 1e-9
                    obj.Phase = obj.Phase + 1;
                end
                sim = obj.Sims{obj.Phase};
                [xNew, sig, u] = sim.step(obj.T, obj.X);
                sig = obj.addDerived(sig);
                s = model.StateVector.unpack(obj.X);
                ext = obj.externalInputs(sim, obj.T);
                obj.TBuf(obj.Idx) = obj.T;
                obj.Buf(obj.Idx, :) = obj.collectSample(s, sig, u, ext);
                obj.X = xNew;
                obj.T = obj.T + sim.Ts;
                obj.Idx = obj.Idx + 1;
            end
            obj.refreshUi();
        end

        function selectScenario(obj, name)
            %SELECTSCENARIO Programmatically switch scenario (dropdown item name).
            obj.ScenarioDD.Value = name;
            obj.loadScenario(name);
        end

        function openComponentChart(obj, id)
            %OPENCOMPONENTCHART Open (or focus) the live chart window of a component.
            if isKey(obj.Charts, id)
                c = obj.Charts(id);
                if isvalid(c.fig)
                    try %#ok<TRYNC>
                        focus(c.fig);
                    end
                    return
                end
                remove(obj.Charts, id);
            end
            def = obj.CompDefs(strcmp({obj.CompDefs.id}, id));
            fig = uifigure('Name', [strrep(def.label, newline, ' ') ' — live'], ...
                'Position', [200 + 30*obj.Charts.Count, 120 + 20*obj.Charts.Count, 640, 460], ...
                'CloseRequestFcn', @(f, ~) obj.onChartClosed(id, f));
            try %#ok<TRYNC>
                fig.Theme = 'light';
            end
            nSig = size(def.signals, 1);
            gl = uigridlayout(fig, [ceil(nSig/2), 2], 'Padding', [8 8 8 8], ...
                'RowSpacing', 6, 'ColumnSpacing', 6);
            lines = gobjects(nSig, 1);
            fieldIdx = zeros(nSig, 1);
            for k = 1:nSig
                ax = uiaxes(gl);
                ax.XLim = [0, obj.TEnd];
                ax.XLimMode = 'manual';
                title(ax, def.signals{k, 2}, 'FontSize', 10);
                xlabel(ax, 't [s]');
                grid(ax, 'on');
                lines(k) = plot(ax, NaN, NaN, 'LineWidth', 1.2);
                fieldIdx(k) = find(strcmp(obj.Fields, def.signals{k, 1}));
            end
            obj.Charts(id) = struct('fig', fig, 'lines', lines, 'fieldIdx', fieldIdx);
            obj.refreshUi();
        end
    end

    methods (Access = private)

        % ------------------------------------------------------ UI setup
        function buildUi(obj)
            obj.Fig = uifigure('Name', 'Usoro 600 MW drum boiler-turbine plant', ...
                'Position', [60 60 1180 720], ...
                'CloseRequestFcn', @(~, ~) delete(obj));
            try %#ok<TRYNC> % Theme exists in newer releases only
                obj.Fig.Theme = 'light';
            end
            gl = uigridlayout(obj.Fig, [2 1], 'RowHeight', {38, '1x'}, ...
                'Padding', [8 8 8 8], 'RowSpacing', 6);

            % toolbar
            tb = uigridlayout(gl, [1 11], 'ColumnWidth', ...
                {70, 150, 64, 64, 64, 70, 58, 90, 44, 78, '1x'}, ...
                'Padding', [0 0 0 0], 'ColumnSpacing', 6);
            lbl = uilabel(tb, 'Text', 'Scenario:', 'HorizontalAlignment', 'right'); %#ok<NASGU>
            obj.ScenarioDD = uidropdown(tb, 'Items', {'Test 1: 100%->77.5%', ...
                'Test 2: 77.5%->50%', 'Test 3: 50%->77.5%', 'Test 4: 77.5%->100%', ...
                'Test 5: voltage drop', 'Test 6: frequency drop', ...
                'Test 7: fan-pair loss', 'Hold 100%'}, ...
                'ValueChangedFcn', @(dd, ~) obj.loadScenario(dd.Value));
            uibutton(tb, 'Text', 'Play', 'ButtonPushedFcn', @(~, ~) obj.onPlay());
            uibutton(tb, 'Text', 'Pause', 'ButtonPushedFcn', @(~, ~) obj.onPause());
            uibutton(tb, 'Text', 'Reset', 'ButtonPushedFcn', @(~, ~) obj.onReset());
            uibutton(tb, 'Text', 'Inputs', ...
                'Tooltip', 'Live charts of the scenario inputs the plant receives', ...
                'ButtonPushedFcn', @(~, ~) obj.openComponentChart('inputs'));
            uilabel(tb, 'Text', 'Speed:', 'HorizontalAlignment', 'right');
            obj.SpeedDD = uidropdown(tb, 'Items', {'1x', '5x', '20x', 'Max'}, ...
                'Value', '20x');
            uilabel(tb, 'Text', 'Run:', 'HorizontalAlignment', 'right');
            obj.DurationDD = uidropdown(tb, ...
                'Items', {'350 s', '700 s', '1400 s', '2800 s'}, ...
                'Value', '700 s', ...
                'Tooltip', ['Simulation end time. Extend it any time - even ' ...
                'after a run finishes - and press Play to continue.'], ...
                'ValueChangedFcn', @(dd, ~) obj.onDurationChanged(dd.Value));
            obj.StatusLabel = uilabel(tb, 'Text', 'ready', 'FontWeight', 'bold');

            % diagram
            obj.Ax = uiaxes(gl);
            obj.Ax.XLim = [0 102];
            obj.Ax.YLim = [-2 62];
            obj.Ax.XTick = [];
            obj.Ax.YTick = [];
            obj.Ax.Toolbar.Visible = 'off';
            disableDefaultInteractivity(obj.Ax);
            hold(obj.Ax, 'on');
            axis(obj.Ax, 'off');
            title(obj.Ax, 'Click a component to open its live charts', ...
                'FontAngle', 'italic', 'FontSize', 11);
            obj.drawDiagram();
        end

        function drawDiagram(obj)
            cSteam = [0.78 0.22 0.16];
            cWater = [0.16 0.36 0.75];
            cGas = [0.45 0.45 0.45];
            % flow connections [x1 y1 x2 y2], drawn first (under the blocks)
            seg = {
                % steam path along the top row
                [14 51 16 51], cSteam; [27 51 30 51], cSteam; [41 51 44 51], cSteam
                [50 51 53 51], cSteam; [74 51 77 51], cSteam                       % gov->HP, IP->LP (cross-over)
                [57.5 46 57.5 33], cSteam; [57.5 33 44 33], cSteam                 % HP exhaust down into reheater
                [44 36 69 36], cSteam; [69 36 69 46], cSteam                       % reheater outlet up into IP
                [81.5 46 81.5 38], cSteam                                          % LP down to condenser
                % shaft to the generator
                [62 51 65 51], [0.25 0.25 0.25]; [86 51 89 51], [0.25 0.25 0.25]
                % feedwater path (right to left)
                [82 28 82 20], cWater; [77 15 74 15], cWater; [63 15 60 15], cWater
                [49 15 46 15], cWater; [35 15 32 15], cWater; [21 15 18 15], cWater
                [12 20 12 46], cWater                                              % economizer up to drum
                % recirculation loop
                [8 46 8 38], cWater; [14 33 16 33], cWater
                % air/gas path
                [8 8 8 28], cGas
                };
            for i = 1:size(seg, 1)
                p = seg{i, 1};
                plot(obj.Ax, [p(1) p(3)], [p(2) p(4)], 'Color', seg{i, 2}, ...
                    'LineWidth', 1.4, 'PickableParts', 'none');
            end
            % component blocks (defs without a position are chart-only)
            for d = obj.CompDefs
                if isempty(d.pos)
                    continue
                end
                patch(obj.Ax, 'XData', d.pos(1) + [0 d.pos(3) d.pos(3) 0], ...
                    'YData', d.pos(2) + [0 0 d.pos(4) d.pos(4)], ...
                    'FaceColor', obj.groupColor(d.group), 'EdgeColor', [0.25 0.25 0.25], ...
                    'LineWidth', 0.8, 'UserData', d.id, ...
                    'ButtonDownFcn', @(src, ~) obj.openComponentChart(src.UserData));
                text(obj.Ax, d.pos(1) + d.pos(3)/2, d.pos(2) + d.pos(4)/2, d.label, ...
                    'HorizontalAlignment', 'center', 'FontSize', 8.6, ...
                    'Color', [0.13 0.13 0.13], 'PickableParts', 'none');
            end
        end

        function c = groupColor(~, g)
            switch g
                case 'steam',   c = [0.99 0.89 0.85];
                case 'water',   c = [0.86 0.91 0.99];
                case 'gas',     c = [0.92 0.92 0.92];
                otherwise,      c = [0.96 0.94 0.82];  % machines
            end
        end

        % ---------------------------------------------------- scenarios
        function loadScenario(obj, name)
            obj.onPause();
            par = obj.Par;
            plant = model.PowerPlant(par);
            ctrl = model.ControlSystem(par);
            hold775 = model.LoadProfile.constant(3.875);
            try
                switch name
                    case 'Test 1: 100%->77.5%'
                        sims = {model.Simulator(plant, ctrl, model.LoadProfile.test1())};
                        x0 = model.InitialConditions.at100();
                        sw = []; tEnd = 700;
                    case 'Test 2: 77.5%->50%'
                        sims = {model.Simulator(plant, ctrl, model.LoadProfile.test2())};
                        x0 = model.InitialConditions.at775();
                        sw = []; tEnd = 700;
                    case 'Test 3: 50%->77.5%'
                        sims = {model.Simulator(plant, ctrl, model.LoadProfile.test3())};
                        x0 = model.InitialConditions.at50();
                        sw = []; tEnd = 700;
                    case 'Test 4: 77.5%->100%'
                        sims = {model.Simulator(plant, ctrl, model.LoadProfile.test4())};
                        x0 = model.InitialConditions.at775();
                        sw = []; tEnd = 700;
                    case 'Test 5: voltage drop'
                        sims = {model.Simulator(plant, ctrl, hold775, model.GridProfile.test5())};
                        x0 = model.InitialConditions.at775();
                        sw = []; tEnd = 350;
                    case 'Test 6: frequency drop'
                        ctrl.gasRecircEnabled = false;
                        sims = {model.Simulator(plant, ctrl, hold775, model.GridProfile.test6())};
                        x0 = model.InitialConditions.at775();
                        sw = []; tEnd = 700;
                    case 'Test 7: fan-pair loss'
                        ctrl.gasRecircEnabled = false;
                        par2 = par;
                        par2.knfd = 1.0;
                        par2.knid = 1.0;
                        ctrl2 = model.ControlSystem(par2);
                        ctrl2.gasRecircEnabled = false;
                        hold100 = model.LoadProfile.constant(5.0);
                        sims = {model.Simulator(plant, ctrl, hold100), ...
                                model.Simulator(model.PowerPlant(par2), ctrl2, hold100)};
                        x0 = model.InitialConditions.at100();
                        sw = 10; tEnd = 700;
                    otherwise % Hold 100%
                        sims = {model.Simulator(plant, ctrl, model.LoadProfile.constant(5.0))};
                        x0 = model.InitialConditions.at100();
                        sw = []; tEnd = 700;
                end
            catch err
                uialert(obj.Fig, err.message, 'Scenario unavailable');
                return
            end
            obj.Sims = sims;
            obj.SwitchTimes = sw;
            obj.X0 = x0;
            obj.TEnd = tEnd;
            obj.DurationDD.Value = sprintf('%d s', tEnd);  % scenario default
            obj.initBuffers();
            obj.onReset();
        end

        function initBuffers(obj)
            % master signal list from the chart registry, source resolved once
            fields = {};
            for d = obj.CompDefs
                fields = [fields; d.signals(:, 1)]; %#ok<AGROW>
            end
            fields = [unique(fields, 'stable'); {'mwo'}];
            fields = unique(fields, 'stable');
            s = model.StateVector.unpack(obj.X0);
            [~, sig, u] = obj.Sims{1}.derivative(0, obj.X0);
            sig = obj.addDerived(sig);
            ext = obj.externalInputs(obj.Sims{1}, 0);
            src = zeros(numel(fields), 1);
            for k = 1:numel(fields)
                if isfield(ext, fields{k})
                    src(k) = 4;
                elseif isfield(s, fields{k})
                    src(k) = 1;
                elseif isfield(sig, fields{k})
                    src(k) = 2;
                elseif isfield(u, fields{k})
                    src(k) = 3;
                else
                    error('PlantApp: unknown signal "%s"', fields{k});
                end
            end
            obj.Fields = fields;
            obj.Src = src;
            n = round(obj.TEnd/obj.Sims{1}.Ts) + 1;
            obj.TBuf = zeros(n, 1);
            obj.Buf = zeros(n, numel(fields));
        end

        function sig = addDerived(obj, sig)
            kmwx = obj.Par.kmwx;
            sig.mwhpMW = sig.mwhp*kmwx;
            sig.mwipMW = sig.mwip*kmwx;
            sig.mwlpMW = sig.mwlp*kmwx;
            sig.mwgnMW = sig.mwgn*kmwx;
        end

        function row = collectSample(obj, s, sig, u, ext)
            n = numel(obj.Fields);
            row = zeros(1, n);
            for k = 1:n
                switch obj.Src(k)
                    case 1, row(k) = s.(obj.Fields{k});
                    case 2, row(k) = sig.(obj.Fields{k});
                    case 3, row(k) = u.(obj.Fields{k});
                    otherwise, row(k) = ext.(obj.Fields{k});
                end
            end
        end

        function ext = externalInputs(~, sim, t)
            % Scenario/boundary inputs the plant is receiving at time t.
            ext.ldc = sim.profile.demand(t);
            ext.gridHz = sim.grid.frequency(t)/(2*pi);
            ext.gridV = sim.grid.voltage(t);
            ext.fanPairs = sim.plant.par.knfd;
        end

        % ------------------------------------------------------ control
        function onPlay(obj)
            if obj.T > obj.TEnd - 1e-9
                return
            end
            obj.Running = true;
            if strcmp(obj.Timer.Running, 'off')
                start(obj.Timer);
            end
        end

        function onPause(obj)
            obj.Running = false;
            if ~isempty(obj.Timer) && isvalid(obj.Timer) && strcmp(obj.Timer.Running, 'on')
                stop(obj.Timer);
            end
            obj.refreshUi();
        end

        function onReset(obj)
            obj.onPause();
            obj.T = 0;
            obj.X = obj.X0;
            obj.Idx = 1;
            obj.Phase = 1;
            for k = keys(obj.Charts)
                c = obj.Charts(k{1});
                if isvalid(c.fig)
                    axs = findall(c.fig, 'Type', 'axes');
                    set(axs, 'XLim', [0, obj.TEnd]);
                end
            end
            obj.refreshUi();
        end

        function onTick(obj)
            if ~obj.Running
                return
            end
            switch obj.SpeedDD.Value
                case '1x',  n = 1;
                case '5x',  n = 4;
                case '20x', n = 16;
                otherwise,  n = 80;
            end
            try
                obj.stepChunk(n);
            catch err
                obj.onPause();
                obj.StatusLabel.Text = ['error: ' err.message];
            end
        end

        function onDurationChanged(obj, val)
            %ONDURATIONCHANGED Set the simulation end time from the dropdown.
            %   Extending grows the signal buffers in place, so a running
            %   (or finished) simulation continues from where it is -
            %   nothing is reset. Shrinking below the current time just
            %   ends the run there; collected samples are kept.
            obj.TEnd = sscanf(val, '%f');
            n = round(obj.TEnd/obj.Sims{1}.Ts) + 1;
            if size(obj.Buf, 1) < n
                obj.TBuf(end+1:n, 1) = 0;
                obj.Buf(end+1:n, :) = 0;
            end
            for k = keys(obj.Charts)
                c = obj.Charts(k{1});
                if isvalid(c.fig)
                    set(findall(c.fig, 'Type', 'axes'), 'XLim', [0, obj.TEnd]);
                end
            end
            obj.refreshUi();
        end

        function onChartClosed(obj, id, fig)
            if isKey(obj.Charts, id)
                remove(obj.Charts, id);
            end
            delete(fig);
        end

        % ------------------------------------------------------ redraw
        function refreshUi(obj)
            n = obj.Idx - 1;
            if n >= 1
                mwoCol = strcmp(obj.Fields, 'mwo');
                obj.StatusLabel.Text = sprintf('t = %.1f s   |   %.1f MW   |   %.0f psia%s', ...
                    obj.TBuf(n), obj.Buf(n, mwoCol), ...
                    obj.Buf(n, strcmp(obj.Fields, 'psso')), ...
                    tern(obj.T > obj.TEnd - 1e-9, '   |   finished', ...
                    tern(obj.Running, '', '   |   paused')));
            else
                obj.StatusLabel.Text = 'ready';
            end
            for k = keys(obj.Charts)
                c = obj.Charts(k{1});
                if ~isvalid(c.fig)
                    continue
                end
                for i = 1:numel(c.lines)
                    if n >= 1
                        set(c.lines(i), 'XData', obj.TBuf(1:n), ...
                            'YData', obj.Buf(1:n, c.fieldIdx(i)));
                    else
                        set(c.lines(i), 'XData', NaN, 'YData', NaN);
                    end
                end
            end
            drawnow limitrate
        end

        % --------------------------------------------------- registry
        function defs = componentRegistry(~)
            % id, label, [x y w h], group, {field, axis title}
            D = {
            'fans',  sprintf('FD / ID fans\n& air path'), [2 0 12 8], 'gas', ...
                {'nfd', 'FD fan speed [rad/s]'; 'nid', 'ID fan speed [rad/s]'; ...
                 'war', 'Air flow [lb/s]'; 'pfn', 'Furnace pressure [psia]'}
            'furnace', sprintf('Furnace &\nwaterwalls'), [2 28 12 10], 'gas', ...
                {'twwm', 'Waterwall metal T [degR]'; 'qwwgm', 'Radiant absorption [Btu/s]'; ...
                 'tfn1', 'Flame temperature [degR]'; 'wfl', 'Fuel flow [lb/s]'}
            'rp', sprintf('Recirculation\npump'), [16 28 10 10], 'mach', ...
                {'nrp', 'Pump speed [rad/s]'; 'wrw', 'Recirc water flow [lb/s]'; ...
                 'pdco', 'Downcomer outlet P [psia]'; 'erp', 'Pump efficiency [-]'}
            'drum', 'Drum', [2 46 12 10], 'steam', ...
                {'vdrw', 'Water volume [ft^3]'; 'pdrs', 'Drum pressure [psia]'; ...
                 'xdrw', 'Drum level [in]'; 'wdrs', 'Steam to primary SH [lb/s]'}
            'psh', sprintf('Primary\nsuperheater'), [16 46 11 10], 'steam', ...
                {'hpso', 'Outlet enthalpy [Btu/lb]'; 'tpso', 'Outlet temperature [degR]'; ...
                 'qps', 'Heat transfer [Btu/s]'; 'wpso', 'Outlet flow [lb/s]'}
            'ssh', sprintf('Spray & sec.\nsuperheater'), [30 46 11 10], 'steam', ...
                {'hsso', 'Main steam enthalpy [Btu/lb]'; 'tsso', 'Main steam T [degR]'; ...
                 'psso', 'Throttle pressure [psia]'; 'wsy', 'Spray flow [lb/s]'}
            'gov', sprintf('Governor\nvalves'), [44 46 6 10], 'mach', ...
                {'agv', 'Valve area [pu]'; 'wtv', 'Throttle flow [lb/s]'; ...
                 'cacvd', 'Valve demand [V]'; 'rsco', 'Steam chest density [lb/ft^3]'}
            'hp', sprintf('HP\nturbine'), [53 46 9 10], 'mach', ...
                {'whp', 'Steam flow [lb/s]'; 'mwhpMW', 'HP power [MW]'; ...
                 'hhpo', 'Exhaust enthalpy [Btu/lb]'; 'ehp', 'Isentropic efficiency [-]'}
            'rh', sprintf('Reheater\n& spray'), [30 28 14 10], 'steam', ...
                {'hrho', 'Outlet enthalpy [Btu/lb]'; 'trho', 'Reheat temperature [degR]'; ...
                 'qrh', 'Heat transfer [Btu/s]'; 'xgg', 'Burner tilt [rad]'}
            'ip', sprintf('IP\nturbine'), [65 46 9 10], 'mach', ...
                {'wip', 'Steam flow [lb/s]'; 'mwipMW', 'IP power [MW]'; ...
                 'hcro', 'Cross-over enthalpy [Btu/lb]'; 'pcro', 'Cross-over pressure [psia]'}
            'lp', sprintf('LP\nturbine'), [77 46 9 10], 'mach', ...
                {'wlp', 'Steam flow [lb/s]'; 'mwlpMW', 'LP power [MW]'; ...
                 'hlpo', 'Exhaust enthalpy [Btu/lb]'; 'pcn', 'Condenser pressure [psia]'}
            'gen', 'Generator', [89 46 10 10], 'mach', ...
                {'mwo', 'Power output [MW]'; 'ntr', 'Shaft speed [rad/s]'; ...
                 'delta', 'Power angle [rad]'; 'mwgnMW', 'Electrical load [MW]'}
            'cond', 'Condenser', [77 28 13 10], 'water', ...
                {'pcn', 'Pressure [psia]'; 'tcn', 'Temperature [degR]'; ...
                 'hcno', 'Hotwell enthalpy [Btu/lb]'; 'qylpo', 'Exhaust quality [-]'}
            'cp', sprintf('Condensate\npump'), [77 10 10 10], 'mach', ...
                {'ncp', 'Pump speed [rad/s]'; 'wcw', 'Condensate flow [lb/s]'; ...
                 'pcpo', 'Discharge pressure [psia]'; 'ecp', 'Pump efficiency [-]'}
            'lph', sprintf('LP feedwater\nheaters'), [63 10 11 10], 'water', ...
                {'hlho', 'Outlet enthalpy [Btu/lb]'; 'qlh', 'Heat transfer [Btu/s]'; ...
                 'w1lhs', 'Extraction 1 [lb/s]'; 'w2lhs', 'Extraction 2 [lb/s]'}
            'dea', 'Deaerator', [49 10 11 10], 'water', ...
                {'vdew', 'Water volume [ft^3]'; 'pdes', 'Pressure [psia]'; ...
                 'xdew', 'Level [in]'; 'wdvo', 'Inlet condensate [lb/s]'}
            'fp', sprintf('Feed pump &\nFP turbine'), [35 10 11 10], 'mach', ...
                {'nfp', 'FP turbine speed [rad/s]'; 'wfp', 'Feed pump flow [lb/s]'; ...
                 'pfpo', 'Discharge pressure [psia]'; 'wft', 'FP turbine steam [lb/s]'}
            'hph', sprintf('HP feedwater\nheater'), [21 10 11 10], 'water', ...
                {'hhho', 'Outlet enthalpy [Btu/lb]'; 'qhh', 'Heat transfer [Btu/s]'; ...
                 'phho', 'Outlet pressure [psia]'; 'whhs', 'Extraction steam [lb/s]'}
            'eco', 'Economizer', [7 10 11 10], 'water', ...
                {'heco', 'Outlet enthalpy [Btu/lb]'; 'qec', 'Heat transfer [Btu/s]'; ...
                 'teco', 'Outlet temperature [degR]'; 'wfw', 'Feedwater flow [lb/s]'}
            'inputs', 'Plant inputs', [], 'mach', ...   % chart-only (Inputs toolbar button)
                {'ldc', 'Load demand LDC [V]'; 'gridHz', 'Grid frequency [Hz]'; ...
                 'gridV', 'Line voltage [V]'; 'fanPairs', 'Operating FD/ID fan pairs [-]'}
            };
            defs = struct('id', D(:, 1), 'label', D(:, 2), 'pos', D(:, 3), ...
                'group', D(:, 4), 'signals', D(:, 5));
            defs = defs';
        end
    end
end

function out = tern(cond, a, b)
if cond
    out = a;
else
    out = b;
end
end
