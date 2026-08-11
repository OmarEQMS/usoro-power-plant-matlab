classdef GridProfile
%GRIDPROFILE Electrical grid condition (frequency, voltage) vs. time.
%   The plant's induction-motor auxiliaries see the line voltage `velec`
%   [V] and the synchronous speed `nelec` [rad/s] (grid frequency x 2*pi);
%   the generator swing equation integrates ntr - nelec. Wrapping both in
%   time functions enables the thesis's electrical emergency tests.
%
%   Examples:
%     grid = model.GridProfile.nominal();  % healthy grid (60 Hz, 4160 V)
%     grid = model.GridProfile.test5();    % thesis Test 5 voltage step
%     grid = model.GridProfile.test6();    % thesis Test 6 frequency ramp
%     grid = model.GridProfile(@(t) 376.991, @(t) 4160*(1 - 0.4*(t>=10)));

    properties (SetAccess = immutable)
        nelecFcn (1,1) function_handle = @(t) 376.991
        velecFcn (1,1) function_handle = @(t) 4160.0
    end

    methods
        function obj = GridProfile(nelecFcn, velecFcn)
            arguments
                nelecFcn (1,1) function_handle
                velecFcn (1,1) function_handle
            end
            obj.nelecFcn = nelecFcn;
            obj.velecFcn = velecFcn;
        end

        function n = frequency(obj, t)
            %FREQUENCY Synchronous speed nelec at time t [rad/s].
            n = obj.nelecFcn(t);
        end

        function v = voltage(obj, t)
            %VOLTAGE Line voltage velec at time t [V].
            v = obj.velecFcn(t);
        end
    end

    methods (Static)
        function obj = nominal()
            %NOMINAL Healthy grid: 60 Hz (376.991 rad/s), 4160 V.
            obj = model.GridProfile(@(t) 376.991, @(t) 4160.0);
        end

        function obj = test5()
            %TEST5 Thesis V.5: 10 s steady, then a 30% step drop in line
            %   voltage (4160 V -> 2912 V). Frequency stays nominal.
            obj = model.GridProfile(@(t) 376.991, ...
                @(t) 4160.0*(1 - 0.30*(t >= 10)));
        end

        function obj = test6()
            %TEST6 Thesis V.6: 10 s steady, then line frequency ramps
            %   60 -> 56 Hz at 0.8 Hz/s over 5 s. Voltage stays nominal.
            obj = model.GridProfile( ...
                @(t) 376.991 - 2*pi*0.8*min(max(t - 10, 0), 5), ...
                @(t) 4160.0);
        end
    end
end
