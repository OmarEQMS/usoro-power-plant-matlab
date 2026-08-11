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
        function obj = ramp(ldc0, ldc1, tStart, rate)
            %RAMP Hold ldc0, then ramp to ldc1 at |rate| V/s from tStart.
            %   The thesis load tests all ramp at 15%/min = 0.0125 V/s
            %   (ldc = 5 x load fraction), which is the default rate.
            arguments
                ldc0 (1,1) double
                ldc1 (1,1) double
                tStart (1,1) double = 10
                rate (1,1) double {mustBePositive} = 0.0125
            end
            dur = abs(ldc1 - ldc0)/rate;
            sgn = sign(ldc1 - ldc0);
            obj = model.LoadProfile(@(t) ldc0 + sgn*rate*max(0, min(t - tStart, dur)));
        end

        function obj = test1()
            %TEST1 Thesis V.1: ramp 100% -> 77.5% (ldc 5 -> 3.875 over 90 s).
            obj = model.LoadProfile.ramp(5.0, 3.875);
        end

        function obj = test2()
            %TEST2 Thesis V.2: ramp 77.5% -> 50% (ldc 3.875 -> 2.5 over 110 s).
            obj = model.LoadProfile.ramp(3.875, 2.5);
        end

        function obj = test3()
            %TEST3 Thesis V.3: ramp 50% -> 77.5% (ldc 2.5 -> 3.875 over 110 s).
            obj = model.LoadProfile.ramp(2.5, 3.875);
        end

        function obj = test4()
            %TEST4 Thesis V.4: ramp 77.5% -> 100% (ldc 3.875 -> 5 over 90 s).
            obj = model.LoadProfile.ramp(3.875, 5.0);
        end

        function obj = constant(level)
            %CONSTANT Fixed LDC signal (1-5 V scale).
            obj = model.LoadProfile(@(t) level);
        end
    end
end
