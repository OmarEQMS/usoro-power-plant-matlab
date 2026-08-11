classdef VesselDynamics
%VESSELDYNAMICS Saturated-vessel balance equations (drum and deaerator).
%   Static transcriptions from the Digital Model (Usoro 1977, Appendix A).

    methods (Static)
        function [f1, f2] = saturatedVessel(kv, vw, rs, rw, hw, hs, ...
                k2, k3, k5, k6, k7, k9, k10, zm, ze)
            % Water-volume and steam-density derivatives of a saturated
            % vessel from its combined mass (zm) and energy (ze) imbalances.
            % The k-coefficients are the saturation-fit slopes; used for
            % both the drum and the deaerator.  (drum.m)
            vs = kv - vw;
            z200 = 2*rs;
            z201 = k2 + k3*z200;
            z202 = k5 + k6*z200 + 3*k7*rs*rs;
            z203 = k9 + k10*z200;
            z204 = rw - rs;
            z205 = vs + vw*z201;
            z207 = rw*hw - rs*hs;
            z208 = vs*hs + vw*hw*z201 + vw*rw*z202 + vs*rs*z203;
            z210 = z204*z208 - z205*z207;
            f1 = (zm*z208 - z205*ze)/z210;
            f2 = (z204*ze - zm*z207)/z210;
        end

        function [wderp, wdewh, wdebd, hderp, hdewh] = deaeratorSteam(wdrs, whp)
            % Deaerator heating-steam sources: recirculation pump seal,
            % waterwall header vents and blowdown.  (destmr.m)
            whp2 = whp*whp;
            wdrs2 = wdrs*wdrs;
            wdrs3 = wdrs2*wdrs;
            wderp = 15.0975;
            wdewh = 8.45534 + 2.8201e-3*whp - 8.58e-7*whp2;
            wdebd = 0.16331 + 7.319e-4*wdrs + 4.462e-6*wdrs2 - 2.51e-9*wdrs3;
            hderp = 295.60;
            hdewh = 179.01095 + 9.66338e-2*whp - 3.55714e-5*whp2;
        end
    end
end
