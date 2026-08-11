classdef LoadProfile
%LOADPROFILE Load Demand Computer (LDC) signal as a function of time.
%   The LDC signal is on the 1-5 V control scale (5 = 100% load = 600 MW).
%   Wraps a function handle so scenarios are swappable without touching the
%   plant or control classes.
%
%   Examples:
%     prof = model.LoadProfile.test1();          % thesis Test 1 ramp
%     prof = model.LoadProfile.constant(5);      % hold 100% load
%     prof = model.LoadProfile(@(t) myLdc(t));   % custom scenario

    properties (SetAccess = immutable)
        demandFcn (1,1) function_handle = @(t) 5.0
    end

    methods
        function obj = LoadProfile(fcn)
            arguments
                fcn (1,1) function_handle
            end
            obj.demandFcn = fcn;
        end

        function ldc = demand(obj, t)
            %DEMAND LDC signal at time t [s].
            ldc = obj.demandFcn(t);
        end
    end

    methods (Static)
        function obj = test1()
            %TEST1 Thesis V.1: 10 s steady, then ramp 100% -> 77.5% at
            %   15%/min (ldc 5 -> 3.875 over 90 s), then hold.
            obj = model.LoadProfile(@(t) 5.0 - 0.0125*max(0, min(t, 100) - 10));
        end

        function obj = constant(level)
            %CONSTANT Fixed LDC signal (1-5 V scale).
            obj = model.LoadProfile(@(t) level);
        end
    end
end
