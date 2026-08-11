classdef Turbomachinery
%TURBOMACHINERY Turbine extraction fits and prime-mover torque models.
%   Static transcriptions from the Digital Model (Usoro 1977, Appendix A).

    methods (Static)
        function [waux, wh] = hpExtraction(w)
            % HP turbine auxiliary and heater extraction flows.  (hpext.m)
            w2 = w*w;
            w3 = w2*w;
            waux = 17.15813 + 1.08e-2*w;
            wh = -7.17593 + 0.09513*w - 8.6643e-5*w2 + 6.187e-8*w3;
        end

        function [w2x, w3x, h2x, p2x, p3x] = ipExtraction(w, p1, po, h1, ho)
            % IP turbine interstage/discharge extractions.  (ipext.m)
            po2 = po*po;
            po3 = po2*po;
            ht = h1 + ho;
            pt = p1 + po;
            w2 = w*w;
            w3 = w2*w;
            w2x = 1.72456 + 2.72665e-2*w + 2.7797e-5*w2;
            w3x = -22.88702 + 0.17584*w - 1.9372e-4*w2 + 1.0479e-7*w3;
            p2x = 0.449904*pt;
            p3x = 32.43505 - 0.4506405*po + 6.851933e-3*po2 - 1.646941e-5*po3;
            h2x = 0.503488*ht;
        end

        function [w1lhs, w2lhs, wdex, wlhst, p1lhs, p2lhs, p3lhs, ...
                h1lhs1, h2lhs1, hdex] = lpExtraction(wlp, pcro, pcn, hcro, hlpo)
            % LP turbine extractions for the LP feedwater heaters.  (lpext.m)
            wlp2 = wlp*wlp;
            wlp3 = wlp2*wlp;
            plpt = pcro + pcn;
            hlpt = hcro + hlpo;
            w1lhs = -1.04759 + 9.97993e-2*wlp - 6.8253e-5*wlp2 + 6.14e-8*wlp3;
            w2lhs = -6.73762 + 8.48847e-2*wlp - 1.3439e-5*wlp2;
            wdex = 4.9696 + 1.75669e-2*wlp + 3.0622e-5*wlp2;
            wlhst = w1lhs + w2lhs;
            p1lhs = 0.13571*plpt;
            p2lhs = 0.029372*plpt;
            p3lhs = 0.63009 - 7.0492e-2*p1lhs + 6.3411e-3*p1lhs*p1lhs ...
                - 1.298e-4*p1lhs*p1lhs*p1lhs;
            h1lhs1 = 0.498953*hlpt;
            h2lhs1 = 0.458364*hlpt;
            hdex = 0.533921*hlpt;
        end

        function [tq1, mw1] = inductionMotor(nelec, velec, knm, n, km, smax)
            % Induction motor torque from the slip characteristic.  (torque.m)
            nmax = nelec/knm;
            s = (nmax - n)/nmax;
            velec2 = velec*velec;
            tq1 = km*velec2/(s/smax + smax/s);
            mw1 = tq1*n;
        end

        function [tqfp1, mwfp1] = feedpumpTurbine(wft, hft1, nfp)
            % Feed pump drive turbine torque from extraction steam.  (fpturb.m)
            kj = 778.17;
            hfto = 1059.0;
            eft = 1.0;
            mwfp1 = wft*(hft1 - hfto)*eft*kj;
            tqfp1 = mwfp1/nfp;
        end
    end
end
