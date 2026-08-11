classdef SteamTables
%STEAMTABLES Polynomial water/steam property fits of the Digital Model.
%   Static, stateless transcriptions of the thesis "Steam Table Fits"
%   (Usoro 1977, Appendix A). Units: p [psia], T [degR], h [Btu/lb],
%   r (density) [lb/ft^3], s (entropy) [Btu/(lb.degR)].
%   Each method notes the legacy src/old file it replaces.

    methods (Static)
        function [rw, hw, hs, ps, Ts] = drumSaturation(rs)
            % Saturated drum water/steam properties from steam density.  (drstat.m)
            rs2 = rs*rs;
            rs3 = rs2*rs;
            rw = 49.27105 - 2.13733*rs + 0.03348*rs2;
            hw = 526.5957 + 31.0437*rs - 0.62086*rs2;
            hs = 1241.713 - 21.3442*rs + 0.20998*rs2;
            ps = 11.1877 + 500.267*rs - 26.4031*rs2 + 0.46944*rs3;
            Ts = 458.084 + 48.2088*rs - 3.2326*rs2 + 0.07249*rs3 + 459.67;
        end

        function [rw, hw, hs, ps, ts] = deaeratorSaturation(rs)
            % Saturated deaerator water/steam properties from steam density.  (destat.m)
            rs2 = rs*rs;
            rs3 = rs2*rs;
            rw = 60.45805 - 19.61207*rs;
            hw = 118.26296 + 1905.63721*rs - 8414.69018*rs2 + 15688.03769*rs3;
            hs = 1143.4984 + 224.556*rs;
            ps = -1.04181 + 419.17159*rs + 131.32803*rs2;
            ts = 150.48933 + 1896.4155*rs - 8447.87828*rs2 + 15757.43239*rs3 + 459.67;
        end

        function [p, T, s] = superheatedSteam(r, h)
            % Superheater steam p,T,s from density and enthalpy.  (shstat.m)
            rh = r*h;
            p = -291.36 - 964.04*r + 0.21781*h + 1.1815*rh;
            T = -1745.1 + 129.1*r + 1.8107*h - 0.066313*rh + 459.67;
            s = 1.3136 - 1.7799e-3*r + 6.3573e-4*h - 8.3591e-2*log(rh);
        end

        function [p, T, s] = reheatSteam(r, h)
            % Reheater steam p,T,s from density and enthalpy.  (rhstat.m)
            rh = r*h;
            p = 27.061 - 1019.1*r - 1.7354e-2*h + 1.2279*rh;
            T = -2013.4 + 189.65*r + 1.9629*h - 9.3054e-2*rh + 459.67;
            s = 1.5015 + 3.8306e-3*r + 6.4181e-4*h - 0.10938*log(rh);
        end

        function [r, T] = feedwater(h, p)
            % Compressed-liquid feedwater density and temperature.  (fwstat.m)
            p2 = p*p;
            h2 = h*h;
            hp = h*p;
            h2p2 = h2*p2;
            r = 71.143 - 5.0804e-3*p - 3.2658e-2*h + 1.1688e-5*hp + 6.1657e-7*p2 ...
                - 3.0631e-5*h2 - 2.3095e-12*h2p2;
            T = 146.98 - 0.088486*p + 0.79716*h + 1.8034e-4*hp + 1.0481e-5*p2 ...
                - 1.8231e-4*h2 - 3.812e-11*h2p2 + 459.67;
        end

        function [r, T] = condensateWater(h, p)
            % Condensate water density and temperature.  (cwstat.m)
            p2 = p*p;
            h2 = h*h;
            hp = h*p;
            r = 62.633 + 2.3086e-4*p - 7.847e-3*h + 8.4526e-7*hp ...
                - 1.3075e-7*p2 - 4.4171e-5*h2;
            T = 31.363 - 3.6799e-3*p + 1.0224*h + 2.2581e-6*hp + 1.3108e-6*p2 ...
                - 9.8358e-5*h2 + 459.67;
        end

        function [h, T] = condensatePumpOutlet(r, p)
            % Condensate pump outlet water enthalpy and temperature.  (cpstat.m)
            p2 = p*p;
            r2 = r*r;
            pr = p*r;
            h = 2668.5 + 24.790*r - 1.7378*p + 0.027264*pr - 1.0745*r2 + 1.0266e-4*p2;
            T = -7918.5 + 366.86*r - 1.7341*p + 0.027146*pr - 3.8292*r2 ...
                + 1.0439e-4*p2 + 459.67;
        end

        function [h, T] = feedpumpOutlet(r, p)
            % Feed pump discharge water enthalpy and temperature.  (fpstat.m)
            r2 = r*r;
            p2 = p*p;
            pr = p*r;
            h = 9024.90 + 0.11479*p - 90.346*r - 2.0528e5/r - 1.8098e-3*pr;
            T = -1268.8 + 82.714*r + 0.10301*p - 1.4744e-3*pr - 0.97073*r2 ...
                - 1.801e-6*p2 + 459.67;
        end

        function [ho, T] = hpTurbineExhaust(s, p, ef, h1)
            % HP turbine exhaust state via isentropic efficiency.  (hpstat.m)
            hi = -485.23 + 1065.28*s + 0.232*p;
            ho = h1 - ef*(h1 - hi);
            T = -1639.24 + 0.119*p + 1.682*ho;
        end

        function [ho, p, T] = crossoverSteam(s, r, ef, h1)
            % IP turbine exhaust / cross-over pipe state.  (crstat.m)
            % Expansion anchored at inlet enthalpy h1 (thesis p. 149); the
            % legacy file originally had the isentropic enthalpy here - see
            % docs/model_old.md, "The crstat.m isentropic-efficiency fix".
            hi = -1211.8 + 683.58*r + 1384.39*s;
            ho = h1 - ef*(h1 - hi);
            p = -381.05 + 0.2783*ho + 668.609*r;
            T = -2074.92 + 2.004*ho + 71.326*r + 459.7;
        end

        function [hlpo, rlpo, slpo, T, rw, hw] = condenser(p, qy)
            % Condenser water/steam and LP exhaust state at quality qy.  (cnstat.m)
            p2 = p*p;
            p3 = p2*p;
            p4 = p3*p;
            p5 = p4*p;
            rw = 62.34525 - 0.28884*p;
            rs = 2.0e-5 + 3.21e-3*p - 3.2e-4*p2 + 8.0e-5*p3;
            hw = -25.80341 + 365.63647*p - 878.10799*p2 + 1305.19564*p3 ...
                - 1002.14134*p4 + 305.01148*p5;
            hs = 1075.86634 + 28.99664*p;
            T = 6.2916 + 364.60878*p - 877.92172*p2 + 1311.45665*p3 ...
                - 1012.17821*p4 + 309.49426*p5 + 459.67;
            sw = -0.05216 + 0.74502*p - 1.84119*p2 + 2.75801*p3 - 2.12467*p4 ...
                + 0.64777*p5;
            ss = 2.21936 - 0.58673*p + 0.51817*p2 - 0.16668*p3;
            hlpo = hw + qy*(hs - hw);
            rlpo = rw + qy*(rs - rw);
            slpo = sw + qy*(ss - sw);
        end

        function [h, r, T] = heaterSteamSat(p)
            % Extraction-heater saturated steam properties.  (lsstat.m)
            p2 = p*p;
            p3 = p2*p;
            h = 126.8737 + 4.15377*p - 0.04224*p2 + 1.8e-4*p3;
            r = 60.53211 - 0.04603*p;
            T = 159.09642 + 4.1294*p - 0.04236*p2 + 1.8e-4*p3 + 459.67;
        end

        function [h, r, T] = heaterWaterSat(p)
            % Extraction-heater saturated water properties.  (lwstat.m)
            p2 = p*p;
            p3 = p2*p;
            h = 32.5 + 43.49757*p - 7.38007*p2 + 0.51472*p3;
            r = 62.34525 - 0.28884*p;
            T = 64.05911 + 43.60199*p - 7.40196*p2 + 0.51616*p3 + 459.67;
        end

        function [h, T, s] = recircWater(r, p)
            % Recirculating (downcomer) water properties.  (rwstat.m)
            rp = r*p;
            r2 = r*r;
            p2 = p*p;
            T = 163.60 + 29.199*r + 4.2676e-2*p - 7.2625e-4*rp - 0.45712*r2 ...
                + 3.1826e-7*p2;
            h = 658.45 + 11.887*r + 3.9498e-2*p - 5.6695e-4*rp - 0.31712*r2 ...
                - 3.2973e-7*p2;
            s = 0.7395 + 1.7257e-2*r + 2.8021e-5*p - 4.7572e-7*rp ...
                - 3.7372e-4*r2 + 2.4354e-10*p2;
        end

        function [r, T, s] = superheatSprayMix(h, p)
            % Superheat spray section outlet steam properties.  (systat.m)
            ph = p*h;
            r = -1.9033 + 1.3862e-3*h + 6.7569e-3*p - 3.7659e-6*ph;
            T = -1654.5 + 1.7443*h + 0.34809*p - 2.0743e-4*ph + 459.67;
            s = 0.46472 + 7.9581e-4*h - 1.1683e-5*p - 1.8658e-8*ph;
        end

        function [r, T, s] = reheatSprayMix(h, p)
            % Reheat spray section outlet steam properties.  (rystat.m)
            p2 = p*p;
            h2 = h*h;
            p2h2 = p2*h2;
            ph = p*h;
            r = -4.2661e-2 + 3.0892e-5*h + 6.2923e-3*p - 3.4891e-6*ph;
            T = -550.34 - 0.39473*h + 1.6795*p - 1.1363e-3*ph + 9.3611e-4*h2 ...
                - 4.1249e-4*p2 + 2.0849e-10*p2h2 + 459.67;
            s = -0.473 + 2.47e-3*h - 2.7302e-4*p - 3.1543e-7*ph - 5.6242e-7*h2 ...
                + 2.8235e-7*p2 + 8.9539e-14*p2h2;
        end
    end
end
