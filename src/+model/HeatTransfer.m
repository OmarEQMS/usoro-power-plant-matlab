classdef HeatTransfer
%HEATTRANSFER Furnace and gas-path heat-transfer models.
%   Static transcriptions from the Digital Model (Usoro 1977, Appendix A).

    methods (Static)
        function [tfn1, twwge, twwgo, qwwgm, qpsr, swwgo] = furnace( ...
                twwm, wwwg, war, sar, tapao, wfl, sfl, tfl, khfl, efl, ...
                wgr, sgr, tgr, uwwgm, ywgr, tpse, upsr)
            % Furnace energy balance: adiabatic flame temperature, then the
            % radiant balance (T^4 terms) solved in closed form for the
            % effective gas temperature.  (thesis FNXFER)
            knp33 = 0.333333; kt0 = 537.0; k1sfn = 0.31; k2sfn = 0.145;
            twwm2 = twwm*twwm;
            twwm4 = twwm2*twwm2;
            tpse2 = tpse*tpse;
            tpse4 = tpse2*tpse2;
            sfn = k1sfn + k2sfn*ywgr;
            tfn1 = kt0 + (wfl*khfl*efl + wfl*sfl*(tfl - kt0) + war*sar* ...
                (tapao - kt0) + wgr*sgr*(tgr - kt0))/(wwwg*sfn);
            z1 = uwwgm + upsr;
            z2 = 2*wwwg*sfn;
            z3 = uwwgm*twwm4 + upsr*tpse4 + z2*tfn1;
            z4 = z2/z1;
            z5 = z3/z1;
            z6 = 0.5*z4*z4;
            z7 = 4*z5/3;
            z8 = sqrt(z7*z7*z7 + z6*z6);
            z9 = (z6 + z8)^knp33;
            z10 = (z8 - z6)^knp33;
            z11 = z9 - z10;
            z12 = sqrt(z11*z11 + 4*z5);
            twwge = 0.5*(sqrt(2*z12 - z11) - sqrt(z11));
            twwgo = 2*twwge - tfn1;
            twwge2 = twwge*twwge;
            twwge4 = twwge2*twwge2;
            qwwgm = uwwgm*(twwge4 - twwm4);
            qpsr = upsr*(twwge4 - tpse4);
            swwgo = sfn;
        end

        function [tgo, q, tme, sgo] = convective(wg, ws, kugm, kums, tse, tg1, qr, ywgr)
            % Convective heat exchanger: series gas-to-metal / metal-to-steam
            % conductances (W^0.6 / W^0.8 laws) with temperature-dependent
            % gas specific heat, solved for the gas outlet temperature.
            % Applied along the flue path: primary SH, secondary SH,
            % reheater, economizer.  (thesis HXFER)
            k0sg = 0.2484; k1sg = 0.1428; ksgt = 10.2272e-6; ksgw = 35.0e-6;
            ws = abs(ws);
            ugm = kugm*wg^0.6;
            ums = kums*ws^0.8;
            ugs = ugm*ums/(ugm + ums);
            z1 = k0sg + k1sg*ywgr;
            z2 = ksgt + ksgw*ywgr;
            z3 = 0.5*ugs;
            z4 = wg*z1;
            z5 = wg*z2;
            z6 = z3 + z4;
            z7 = z3*tg1 - ugs*tse - z5*tg1*tg1 - z4*tg1;
            tgo = 0.5*(sqrt(z6*z6 - 4*z5*z7) - z6)/z5;
            sg = z1 + z2*(tg1 + tgo);
            qc = wg*sg*(tg1 - tgo);
            q = qc + qr;
            tme = tse + qc/ums;
            sgo = z1 + z2*2*tgo;
        end
    end
end
