classdef StateVector
%STATEVECTOR Index map and pack/unpack helpers for the 47-state vector.
%   State ordering follows the thesis data deck (Usoro 1977, p. 288):
%   states 1-22 and 47 are physical, 23-46 belong to the control system.
%   See docs/model.md, "State vector", for the full table with units.

    properties (Constant)
        NFP   = 1;   % feed pump turbine speed              [rad/s]
        HHHO  = 2;   % HP feedwater heater outlet enthalpy  [Btu/lb]
        HECO  = 3;   % economizer outlet enthalpy           [Btu/lb]
        VDRW  = 4;   % drum water volume                    [ft^3]
        RDRS  = 5;   % drum steam density                   [lb/ft^3]
        NRP   = 6;   % recirculation pump speed             [rad/s]
        TWWM  = 7;   % waterwall metal temperature          [degR]
        RPSO  = 8;   % primary superheater outlet density   [lb/ft^3]
        HPSO  = 9;   % primary superheater outlet enthalpy  [Btu/lb]
        RSSO  = 10;  % secondary superheater outlet density [lb/ft^3]
        HSSO  = 11;  % secondary superheater outlet enthalpy[Btu/lb]
        RSCO  = 12;  % steam chest density                  [lb/ft^3]
        RRHO  = 13;  % reheater outlet density              [lb/ft^3]
        HRHO  = 14;  % reheater outlet enthalpy             [Btu/lb]
        RCRO  = 15;  % cross-over pipe density              [lb/ft^3]
        NTR   = 16;  % turbine-generator speed              [rad/s]
        NCP   = 17;  % condensate pump speed                [rad/s]
        HLHO  = 18;  % LP feedwater heater outlet enthalpy  [Btu/lb]
        VDEW  = 19;  % deaerator water volume               [ft^3]
        RDES  = 20;  % deaerator steam density              [lb/ft^3]
        NFD   = 21;  % forced-draft fan speed               [rad/s]
        NID   = 22;  % induced-draft fan speed              [rad/s]
        C3MD  = 23;  % boiler master integrator
        C5AR  = 24;  % air flow integrator
        C5FL  = 25;  % fuel flow integrator
        C3FN  = 26;  % furnace pressure integrator
        C2GR  = 27;  % gas recirculation integrator
        C2FT  = 28;  % feedpump turbine integrator
        C3FV  = 29;  % feedwater level integrator
        C7FV  = 30;  % feedwater flow integrator
        C3DV  = 31;  % deaerator level integrator
        C8DV  = 32;  % deaerator trim integrator
        C5RH  = 33;  % reheat temperature integrator
        C5SY  = 34;  % superheat temperature integrator
        CARD  = 35;  % combustion air demand lag
        CFLD  = 36;  % fuel flow demand lag
        CFND  = 37;  % furnace pressure demand lag
        CGRD  = 38;  % gas recirculation demand lag
        CFTD  = 39;  % feedpump turbine steam demand lag
        CFWD  = 40;  % feedwater valve demand lag
        CDWD  = 41;  % deaerator valve demand lag
        CXGGD = 42;  % burner tilt demand lag
        CSYD  = 43;  % superheat spray demand lag
        C2TR  = 44;  % load reference integrator
        C4TR  = 45;  % turbine load demand lag
        CACVD = 46;  % governor valve demand lag
        DELTA = 47;  % generator power angle                [rad]
    end

    methods (Static)
        function s = unpack(x)
            %UNPACK Map a 47x1 state vector onto a struct with named fields.
            n = model.StateVector.names();
            for k = 1:47
                s.(n{k}) = x(k);
            end
        end

        function n = names()
            %NAMES Lower-case state names in vector order.
            n = {'nfp','hhho','heco','vdrw','rdrs','nrp','twwm','rpso', ...
                 'hpso','rsso','hsso','rsco','rrho','hrho','rcro','ntr', ...
                 'ncp','hlho','vdew','rdes','nfd','nid','c3md','c5ar', ...
                 'c5fl','c3fn','c2gr','c2ft','c3fv','c7fv','c3dv','c8dv', ...
                 'c5rh','c5sy','card','cfld','cfnd','cgrd','cftd','cfwd', ...
                 'cdwd','cxggd','csyd','c2tr','c4tr','cacvd','delta'};
        end
    end
end
