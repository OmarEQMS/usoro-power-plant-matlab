classdef Hydraulics
%HYDRAULICS Closed-form flow-network solvers of the Digital Model.
%   Static transcriptions of the thesis flow subroutines (Usoro 1977,
%   Appendix A): each combines pump/fan performance quadratics with pipe
%   friction and solves the resulting quadratic for the flow. Local fit
%   coefficients are kept inside each method, subroutine-local exactly as
%   in the thesis FORTRAN.

    methods (Static)
        function w = orificeFlow(r, pd, kf)
            % Steam flow from a momentum balance, sign-preserving.  (thesis SHFLOW)
            kd1 = 1;
            if pd < 0
                pd = -pd;
                kd1 = -1;
            end
            w = kd1*sqrt(pd*r/kf);
        end

        function [wfp, wfw, wfw2, pbpo, pfpo, pfvo, phho, pfvd, efp] = ...
                feedwater(wry, wsy, rdew, pdes, pdrs, reco, afv, nfp)
            % Booster + main feed pump network: pump curves in series with
            % the feedwater valve, HP heater and economizer friction,
            % solved for feed pump flow.  (thesis FWFLOW, pp. 159-161)
            k1fp = -57.3012e-3; k2fp = 959.4371e-6; k3fp = 203.8473e-6;
            k4fp = -1.735761e-3; k5fp = 129.1779e-6; k6fp = 548.9264e-9;
            k1bp = -2.63447e-3; k2bp = 200.721e-6; k3bp = 99.9049e-6;
            kfhh = 4.7469e-3; kfec = 3.878121e-3; kfv = 1.1721e-3;
            kwfpx = 19.6677; knbpr = 0.333333;
            knbpr2 = knbpr*knbpr; %#ok<NASGU> % unused, kept as in the thesis listing
            nbp = knbpr*nfp;
            nbp2 = nbp*nbp;
            nfp2 = nfp*nfp;
            afv2 = afv*afv;
            z1 = kwfpx + wry + wsy;
            z2 = kfv/(afv2*rdew);
            z3 = kfhh/rdew;
            z4 = kfec/reco;
            z5 = k1fp/rdew;
            z6 = k1bp/rdew;
            z7 = k2fp*nfp;
            z8 = k2bp*nbp;
            z9 = k3fp*nfp2*rdew;
            z10 = k3bp*nbp2*rdew;
            z11 = z2 + z3 + z4;
            z12 = z5 + z6;
            z13 = z7 + z8;
            z14 = z9 + z10 + pdes - pdrs;
            z15 = z11 - z12;
            z16 = 2*z11*z1 + z13;
            z17 = z14 - z11*z1*z1;
            wfp = 0.5*(sqrt(z16*z16 + 4*z15*z17) + z16)/z15;
            wfw = wfp - z1;
            wfp2 = wfp*wfp;
            wfw2 = wfw*wfw;
            pbpo = pdes + z6*wfp2 + z8*wfp + z10;
            pfpo = pbpo + z5*wfp2 + z7*wfp + z9;
            pfvo = pfpo - z2*wfw2;
            phho = pfvo - z3*wfw2;
            pfvd = pfpo - pfvo;
            efp = k4fp*wfp2/(rdew*rdew) + k5fp*wfp*nfp/rdew + k6fp*nfp2;
        end

        function [wcw, wcp, pcpo, plho, wlhx, wdvo, ecp] = ...
                condensate(pcn, rcno, rdvo, pdes, ncp, adv, kncp)
            % Condensate pump network: pump curve, LP heater friction and
            % deaerator valve, solved for condensate pump flow.  (thesis CWFLOW)
            kflh = 3.914168e-3; kdv = 9.434e-3; k1cp = -1.64515e-2;
            k2cp = 1.20115e-4; k3cp = 1.57933e-4; k4cp = -8.88465e-3;
            k5cp = 9.2870e-4; k6cp = 4.34174e-7; k1lhx = 25.60544;
            k2lhx = 7.32295e-2; k3lhx = -1.6317e-5;
            adv2 = adv*adv;
            ncp2 = ncp*ncp;
            kncp2 = kncp*kncp;
            z1 = k1cp/rcno;
            z2 = k2cp*ncp;
            z3 = k3cp*ncp2*rcno;
            z4 = kflh*kncp2/rcno;
            z5 = kdv*kncp2/(adv2*rdvo);
            z6 = z4 + z5 - z1;
            z7 = z3 + pcn - pdes;
            wcp = 0.5*(sqrt(z2*z2 + 4*z6*z7) + z2)/z6;
            wcw = kncp*wcp;
            wcp2 = wcp*wcp;
            wcw2 = wcw*wcw;
            wlhx = k1lhx + k2lhx*wcw + k3lhx*wcw2;
            wdvo = wcw - wlhx;
            pcpo = pcn + z1*wcp2 + z2*wcp + z3;
            plho = pcpo - z4*wcp2;
            ecp = k4cp*wcp2/(rcno*rcno) + k5cp*wcp*ncp/rcno + k6cp*ncp2;
        end

        function [wrw, wrp, wwwo, pdco, prpo, erp] = ...
                recirculation(knrp, rdc, rdrw, nrp, pdrs)
            % Recirculation pump network: downcomer/waterwall friction and
            % static head, solved for pump flow.  (thesis RWFLOW)
            kn144 = 144.0; kldc = 137.0; kwrps = 4.3014; k1rp = -1.73366e-3;
            k2rp = 1.64728e-4; k3rp = 5.5798e-5; k4rp = -1.3391e-3;
            k5rp = 3.45853e-4; k6rp = 2.8937e-6; kfdc = 381.048e-6;
            kfww = 84.6537e-6;
            nrp2 = nrp*nrp;
            knrp2 = knrp*knrp;
            z1 = kfdc/rdc;
            z2 = kldc*rdc/kn144;
            z3 = k1rp/rdc;
            z4 = k2rp*nrp;
            z5 = k3rp*nrp2*rdc;
            z6 = kfww/rdrw;
            z7 = kldc*rdrw/kn144;
            z8 = z1 - z3 + z6*knrp2;
            z9 = z4 - 2*z6*knrp*kwrps;
            z10 = z5 + z2 - z7 - z6*kwrps*kwrps;
            wrp = 0.5*(sqrt(z9*z9 + 4*z8*z10) + z9)/z8;
            wrw = knrp*wrp;
            wwwo = wrw + kwrps;
            wrp2 = wrp*wrp;
            pdco = pdrs - z1*wrp2 + z2;
            prpo = pdco + z3*wrp2 + z4*wrp + z5;
            erp = k4rp*wrp2/(rdc*rdc) + k5rp*wrp*nrp/rdc + k6rp*nrp2;
        end

        function [war, wwwg, wfd, wgo, wid, pahao, pfdo, pfn, pecgo, papgo, ...
                pido, efd, eid] = airGas(knfd, knid, nfd, nid, wgr, wfl, avf, avi)
            % Air-gas path: FD and ID fan curves, air heater, furnace and
            % gas-side friction, solved for FD fan flow.  (thesis ARFLOW)
            kpat = 14.7;
            % Fan-curve calibration kfcal: the printed listing's fans max
            % out at ~1219 lb/s of air (dampers full open, IC fan speeds),
            % but the 100% point needs 1230.0 lb/s through the fuel/air
            % cross-limit, and Table V.1/Fig. V.7 report 1230.3 lb/s at
            % only ~4.55 V of air control - the thesis's published runs
            % had stronger fans than its printed deck. x1.10 on the fan
            % dP coefficients (~+5% air capacity) restores the published
            % behavior (100% holds, Test 4 settles on Table V.1, Test 6
            % lands on Fig. V.10). Power terms k4-k6 stay as printed.
            % See docs/model.md, "Known quantitative offsets".
            kfcal = 1.10;
            k1fd = -7.41568e-7*kfcal; k2fd = 8.67456e-6*kfcal; k3fd = 1.67206e-4*kfcal;
            k4fd = -2.18247e-6; k5fd = 5.13044e-5; k6fd = -6.96849e-5;
            k1id = -1.38148e-6*kfcal; k2id = 1.12227e-5*kfcal; k3id = 1.09727e-4*kfcal;
            k4id = -1.12212e-6; k5id = 1.74023e-5; k6id = 3.43528e-5;
            kfah = 1.82764e-7; kfapa = 3.968e-7; kfg = 263.7944e-9;
            kfapg = 1.176409e-7; kfst = 2.109e-7;
            pstd = 7.216667e-2;
            nfd2 = nfd*nfd;
            nid2 = nid*nid;
            knfd2 = knfd*knfd;
            knid2 = knid*knid;
            wfl2 = wfl*wfl;
            z1 = wfl + wgr;
            z2 = k1fd/avf;
            z4 = knfd2*kfapa;
            z5 = kfah + z4 - z2;
            z6 = kfapg + kfst;
            z7 = k1id/avi;
            z9 = -z7;
            z10 = k2fd*nfd;
            z11 = k2id*nid;
            z12 = k3fd*nfd2*avf;
            z13 = k3id*nid2*avi;
            z14 = z12 + z13 + pstd;
            z15 = z9/knid2;
            z16 = z5 + knfd2*(kfg + z6 + z15);
            z17 = 2*knfd*(kfg*z1 + z6*wfl + z15*wfl) - z10 - z11*knfd/knid;
            z18 = kfg*z1*z1 + wfl2*(z6 + z15) - z11*wfl/knid - z14;
            wfd = 0.5*(sqrt(z17*z17 - 4*z16*z18) - z17)/z16;
            war = knfd*wfd;
            wwwg = war + z1;
            wgo = war + wfl;
            wid = wgo/knid;
            wfd2 = wfd*wfd;
            wwwg2 = wwwg*wwwg;
            wgo2 = wgo*wgo;
            wid2 = wid*wid;
            pahao = kpat - kfah*wfd2;
            pfdo = pahao + z2*wfd2 + z10*wfd + z12;
            pfn = pfdo - z4*wfd2;
            pecgo = pfn - kfg*wwwg2;
            papgo = pecgo - kfapg*wgo2;
            pido = papgo + z7*wid2 + z11*wid + z13;
            efd = k4fd*wfd2 + k5fd*wfd*nfd + k6fd*nfd2;
            eid = k4id*wid2 + k5id*wid*nid + k6id*nid2;
        end
    end
end
