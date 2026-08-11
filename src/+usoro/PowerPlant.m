classdef PowerPlant < handle
%POWERPLANT Physical process model of the Usoro 47th-order Digital Model.
%   Computes the algebraic plant relations and the 23 physical state
%   derivatives (states 1-22 and 47) as a pure function of the state and
%   the actuator commands. The control-system states are advanced by
%   usoro.ControlSystem; usoro.Simulator combines both.
%
%   The evaluation order follows the thesis/legacy computation sequence
%   (see docs/model_oop.md). All intermediate variables are accumulated in
%   a signal struct `sig` under their thesis names, which also serves the
%   control system and the logger.

    properties (SetAccess = immutable)
        par usoro.Parameters
    end

    methods
        function obj = PowerPlant(par)
            arguments
                par (1,1) usoro.Parameters = usoro.Parameters()
            end
            obj.par = par;
        end

        function [xdot, sig] = evaluate(obj, s, u)
            %EVALUATE Physical derivatives and plant signals at state s, actuators u.
            sig = struct();
            sig = obj.thermoStates(s, sig);
            sig = obj.steamPathAndTurbines(s, u, sig);
            sig = obj.waterSide(s, u, sig);
            sig = obj.mixingAndHeaters(s, u, sig);
            sig = obj.airGasSide(s, u, sig);
            sig = obj.effectiveMasses(s, sig);
            sig = obj.vesselBalances(s, sig);
            sig = obj.machines(s, u, sig);
            xdot = obj.physicalDerivatives(s, sig);
        end
    end

    methods (Access = private)
        function sig = thermoStates(obj, s, sig)
            % Thermodynamic state of each storage element from its state pair.
            [sig.rdrw, sig.hdrw, sig.hdrs, sig.pdrs, sig.tdrs] = ...
                usoro.SteamTables.drumSaturation(s.rdrs);
            [sig.rdew, sig.hdew, sig.hdes, sig.pdes, sig.tdes] = ...
                usoro.SteamTables.deaeratorSaturation(s.rdes);
            [sig.ppso, sig.tpso, sig.spso] = usoro.SteamTables.superheatedSteam(s.rpso, s.hpso);
            [sig.psso, sig.tsso, sig.ssso] = usoro.SteamTables.superheatedSteam(s.rsso, s.hsso);
            % steam chest shares the secondary superheater outlet enthalpy
            [sig.psco, sig.tsco, sig.ssco] = usoro.SteamTables.superheatedSteam(s.rsco, s.hsso);
            [sig.prho, sig.trho, sig.srho] = usoro.SteamTables.reheatSteam(s.rrho, s.hrho);
            [sig.reco, sig.teco] = usoro.SteamTables.feedwater(s.heco, sig.pdrs);
            [sig.rdvo, sig.tdvo] = usoro.SteamTables.condensateWater(s.hlho, sig.pdes);
        end

        function sig = steamPathAndTurbines(obj, s, u, sig)
            % Main steam flows, turbine powers and generator load.
            P = obj.par;
            sig.ppsd = sig.pdrs - sig.ppso;
            sig.wdrs = usoro.Hydraulics.orificeFlow(s.rdrs, sig.ppsd, P.kfps);
            sig.acv = u.agv;
            sig.wtv = P.kcv*sig.acv*sqrt(sig.psso*s.rsso);
            % primary superheater bypass flow at low throttle flow
            sig.wpsx = P.kn0;
            if sig.wtv < P.kwtv
                sig.wpsx = 101.56064 - 0.39882*sig.wdrs + 4.8626e-4*sig.wdrs*sig.wdrs;
            end
            sig.pssd = sig.ppso - sig.psso;
            sig.wss1 = usoro.Hydraulics.orificeFlow(s.rsso, sig.pssd, P.kfss);
            sig.wpso = sig.wss1 + sig.wpsx - u.wsy;
            sig.whp = P.khp*sqrt(s.rsco*sig.psco);
            % feed pump turbine takes main steam instead of IP extraction at low load
            sig.wssx = P.kn0;
            if sig.wtv < P.kwtv
                sig.wssx = u.wft;
            end
            sig.wsso = sig.wtv + sig.wssx;
            [sig.whpaux, sig.w1hhs] = usoro.Turbomachinery.hpExtraction(sig.whp);
            sig.whpo = sig.whp - sig.whpaux - sig.w1hhs;
            sig.wrh1 = sig.whpo + u.wry;
            sig.wiv = P.kip*u.aiv*sqrt(s.rrho*sig.prho);
            sig.wip = sig.wiv;
            % turbine expansions (efficiencies per thesis pp. 145-151)
            sig.ehp = 0.589 + 2.317e-4*sig.whp;
            sig.phpo = sig.prho + P.kfrh*sig.wip*sig.wip/s.rrho;
            [sig.hhpo, sig.thpo] = usoro.SteamTables.hpTurbineExhaust( ...
                sig.ssso, sig.phpo, sig.ehp, s.hsso);
            sig.eip = 0.814;
            [sig.hcro, sig.pcro, sig.tcro] = usoro.SteamTables.crossoverSteam( ...
                sig.srho, s.rcro, sig.eip, s.hrho);
            sig.wlp = P.klp*sqrt(s.rcro*sig.pcro);
            sig.pcn = P.k0pcn + P.k1pcn*sig.pcro + P.k2pcn*sig.pcro*sig.pcro;
            sig.qylpo = P.kqylpo;
            [sig.hlpo, sig.rlpo, sig.slpo, sig.tcn, sig.rcno, sig.hcno] = ...
                usoro.SteamTables.condenser(sig.pcn, sig.qylpo);
            keip = 0.93;
            kelp = 0.93;
            sig.mwhp = sig.whp*(s.hsso - sig.hhpo)*P.kj;
            sig.mwip = sig.wip*(s.hrho - sig.hcro)*P.kj*keip;
            sig.mwlp = sig.wlp*(sig.hcro - sig.hlpo)*P.kj*kelp;
            sig.mwtro = sig.mwhp + sig.mwip + sig.mwlp;
            sig.mwo = sig.mwtro*P.kmwx;
            % generator action (infinite bus, thesis pp. 152-153)
            sig.mwgnpu = P.kn2*sin(s.delta);
            sig.mwgn = sig.mwgnpu*P.kmwr;
            sig.mwtrpu = sig.mwtro/P.kmwr;
            [sig.w2hhs, sig.w3hhs, sig.h2hhs1, sig.p2hhs, sig.p3hhso] = ...
                usoro.Turbomachinery.ipExtraction(sig.wip, sig.prho, sig.pcro, s.hrho, sig.hcro);
            sig.wipftx = u.wft;
            if sig.wssx > P.kn0
                sig.wipftx = P.kn0;
            end
            sig.wipo = sig.wip - sig.w2hhs - sig.w3hhs - sig.wipftx;
        end

        function sig = waterSide(obj, s, u, sig)
            % Condensate, feedwater and recirculation flow networks.
            P = obj.par;
            [sig.wcw, sig.wcp, sig.pcpo, sig.plho, sig.wlhx, sig.wdvo, sig.ecp] = ...
                usoro.Hydraulics.condensate(sig.pcn, sig.rcno, sig.rdvo, ...
                sig.pdes, s.ncp, u.adv, P.kncp);
            [sig.hcpo, sig.tcpo] = usoro.SteamTables.condensatePumpOutlet(sig.rcno, sig.pcpo);
            [sig.rlho, sig.tlho] = usoro.SteamTables.condensateWater(s.hlho, sig.plho);
            [sig.wfp, sig.wfw, sig.wfw2, sig.pbpo, sig.pfpo, sig.pfvo, ...
                sig.phho, sig.pfvd, sig.efp] = usoro.Hydraulics.feedwater( ...
                u.wry, u.wsy, sig.rdew, sig.pdes, sig.pdrs, sig.reco, u.afv, s.nfp);
            [sig.hfpo, sig.tfpo] = usoro.SteamTables.feedpumpOutlet(sig.rdew, sig.pfpo);
            sig.hfvo = sig.hfpo;
            [sig.rhho, sig.thho] = usoro.SteamTables.feedwater(s.hhho, sig.phho);
            sig.rdc = sig.rdrw;
            [sig.wrw, sig.wrp, sig.wwwo, sig.pdco, sig.prpo, sig.erp] = ...
                usoro.Hydraulics.recirculation(P.knrp, sig.rdc, sig.rdrw, s.nrp, sig.pdrs);
        end

        function sig = mixingAndHeaters(obj, s, u, sig)
            % Downcomer/spray heat balances, extraction heaters, mean section
            % properties for the heat-exchanger chain.
            P = obj.par;
            sig.hdc1 = (sig.wfw*s.heco + sig.hdrw*(sig.wrw - sig.wfw))/sig.wrw;
            sig.hss1 = ((sig.wpso - sig.wpsx)*s.hpso + u.wsy*sig.hfpo)/sig.wss1;
            sig.hrh1 = (sig.whpo*sig.hhpo + u.wry*sig.hfpo)/sig.wrh1;
            [sig.rdc1, sig.tdc1] = usoro.SteamTables.feedwater(sig.hdc1, sig.pdrs);
            [sig.hdco, sig.tdco, sig.sdco] = usoro.SteamTables.recircWater(sig.rdc1, sig.pdco);
            [sig.hrpo, sig.trco, sig.srpo] = usoro.SteamTables.recircWater(sig.rdc1, sig.prpo);
            [sig.rss1, sig.tss1, sig.sss1] = usoro.SteamTables.superheatSprayMix(sig.hss1, sig.ppso);
            [sig.rrh1, ~, ~] = usoro.SteamTables.reheatSprayMix(sig.hrh1, sig.phpo);
            [sig.w1lhs, sig.w2lhs, sig.wdex, sig.wlhst, sig.p1lhs, sig.p2lhs, ...
                sig.p3lhs, sig.h1lhs1, sig.h2lhs1, sig.hdex] = ...
                usoro.Turbomachinery.lpExtraction(sig.wlp, sig.pcro, sig.pcn, sig.hcro, sig.hlpo);
            [sig.h1lhso, sig.r1lhso, sig.t1lhso] = usoro.SteamTables.heaterSteamSat(sig.p1lhs);
            [sig.h2lhso, sig.r2lhso, sig.t2lhso] = usoro.SteamTables.heaterWaterSat(sig.p2lhs);
            [sig.h3lhso, sig.r3lhso, sig.t3lhso] = usoro.SteamTables.heaterWaterSat(sig.p3lhs);
            sig.qlh = sig.w1lhs*(sig.h1lhs1 - sig.h3lhso) + sig.w2lhs*(sig.h2lhs1 - sig.h2lhso);
            sig.whhst = sig.w1hhs + sig.w2hhs + sig.w3hhs;
            [sig.h3hhso, sig.r3hhso, sig.t3hhso] = usoro.SteamTables.heaterSteamSat(sig.p3hhso);
            sig.qhh = sig.w1hhs*sig.hhpo + sig.w2hhs*sig.h2hhs1 + sig.w3hhs*sig.hcro ...
                - sig.whhst*sig.h3hhso;
            sig.whhs = sig.whhst;
            if sig.wfw < P.kwfw
                sig.whhs = P.kn0;
            end
            % mean flow, density, enthalpy and pressure per section
            [sig.wpse, sig.rpse, sig.hpse] = obj.avg3(sig.wdrs, sig.wpso, ...
                s.rdrs, s.rpso, sig.hdrs, s.hpso);
            [sig.wsse, sig.rsse, sig.hsse] = obj.avg3(sig.wss1, sig.wsso, ...
                sig.rss1, s.rsso, sig.hss1, s.hsso);
            [sig.wrhe, sig.rrhe, sig.hrhe] = obj.avg3(sig.wrh1, sig.wip, ...
                sig.rrh1, s.rrho, sig.hrh1, s.hrho);
            [sig.pece, sig.hece, sig.plhe] = obj.avg3(sig.phho, sig.pdrs, ...
                s.hhho, s.heco, sig.pcpo, sig.plho);
            [sig.phhe, sig.hhhe, sig.hlhe] = obj.avg3(sig.pfvo, sig.phho, ...
                sig.hfvo, s.hhho, sig.hcpo, s.hlho);
            [sig.ppse, sig.tpse, sig.spse] = usoro.SteamTables.superheatedSteam(sig.rpse, sig.hpse);
            [sig.psse, sig.tsse, sig.ssse] = usoro.SteamTables.superheatedSteam(sig.rsse, sig.hsse);
            [sig.prhe, sig.trhe, sig.srhe] = usoro.SteamTables.reheatSteam(sig.rrhe, sig.hrhe);
            [sig.rece, sig.tece] = usoro.SteamTables.feedwater(sig.hece, sig.pece);
            [sig.rhhe, sig.thhe] = usoro.SteamTables.feedwater(sig.hhhe, sig.phhe);
            [sig.rlhe, sig.tlhe] = usoro.SteamTables.condensateWater(sig.hlhe, sig.plhe);
        end

        function sig = airGasSide(obj, s, u, sig)
            % Air-gas path, furnace and flue-gas heat-transfer chain.
            P = obj.par;
            [sig.war, sig.wwwg, sig.wfd, sig.wgo, sig.wid, sig.pahao, sig.pfdo, ...
                sig.pfn, sig.pecgo, sig.papgo, sig.pido, sig.efd, sig.eid] = ...
                usoro.Hydraulics.airGas(P.knfd, P.knid, s.nfd, s.nid, ...
                u.wgr, u.wfl, u.avf, u.avi);
            sig.tahao = P.ktat + P.ktahad;
            sig.tapao = sig.tahao + P.ktapad;
            sig.ward = P.kafr*u.wfl;
            % burner tilt and gun-count correction of waterwall absorption
            sig.uxgg = P.k1xgg + P.k2xgg*sin(u.xgg)/cos(u.xgg);
            sig.ngg = P.ng1 + P.ng2 + P.ng3 + P.ng4 + P.ng5;
            sig.ungg = (P.ng1*P.k1ng + P.ng2*P.k2ng + P.ng3*P.k3ng + ...
                P.ng4*P.k4ng + P.ng5*P.k5ng)/(sig.ngg*P.kxwwe);
            sig.uwwgm = P.kuwwgm*sig.uxgg*sig.ungg;
            sig.tgr = P.k1tgr + P.k2tgr*u.wfl;
            [sig.tfn1, sig.twwge, sig.twwgo, sig.qwwgm, sig.qpsr, sig.swwgo] = ...
                usoro.HeatTransfer.furnace(s.twwm, sig.wwwg, sig.war, P.sar, ...
                sig.tapao, u.wfl, P.sfl, P.tfl, P.khfl, P.efl, u.wgr, P.sgr, ...
                sig.tgr, sig.uwwgm, P.ywgr, sig.tpse, P.kupsr);
            sig.qwwmw = P.kuwwmw*(s.twwm - sig.tdrs)^3;
            % convective chain in flue-gas order (radiant additions qr = 0
            % except the primary superheater, which receives qpsr)
            sig.qssr = P.kn0;
            sig.qrhr = P.kn0;
            sig.qecr = P.kn0;
            [sig.tpsgo, sig.qps, sig.tpsme, sig.spsgo] = usoro.HeatTransfer.convective( ...
                sig.wwwg, sig.wpse, P.kupsgm, P.kupsms, sig.tpse, sig.twwgo, sig.qpsr, P.ywgr);
            [sig.tssgo, sig.qss, sig.tssme, sig.sssgo] = usoro.HeatTransfer.convective( ...
                sig.wwwg, sig.wsse, P.kussgm, P.kussms, sig.tsse, sig.tpsgo, sig.qssr, P.ywgr);
            [sig.trhgo, sig.qrh, sig.trhme, sig.srhgo] = usoro.HeatTransfer.convective( ...
                sig.wwwg, sig.wrhe, P.kurhgm, P.kurhms, sig.trhe, sig.tssgo, sig.qrhr, P.ywgr);
            [sig.tecgo, sig.qec, sig.tecme, sig.secgo] = usoro.HeatTransfer.convective( ...
                sig.wwwg, sig.wfw, P.kuecgm, P.kuecmw, sig.tece, sig.trhgo, sig.qecr, P.ywgr);
            sig.tlhme = P.klhm*sig.tlho;
            sig.thhme = P.khhm*sig.thho;
        end

        function sig = effectiveMasses(obj, s, sig)
            % Effective (fluid + lumped metal) masses of the heat exchangers.
            P = obj.par;
            sig.mwwme = P.kmwwm + P.kvww*sig.rdrw*sig.hdrw/(P.kswwm*s.twwm);
            sig.mpss = sig.rpse*P.kvps;
            sig.mpse = sig.mpss + P.kmpsm*P.kspsm*sig.tpsme/sig.hpse;
            sig.msss = sig.rsse*P.kvss;
            sig.msse = sig.msss + P.kmssm*P.ksssm*sig.tssme/sig.hsse;
            sig.mrhs = sig.rrhe*P.kvrh;
            sig.mrhe = sig.mrhs + P.kmrhm*P.ksrhm*sig.trhme/sig.hrhe;
            sig.mecw = sig.rece*P.kvec;
            sig.mece = sig.mecw + P.kmecm*P.ksecm*sig.tecme/sig.hece;
            sig.mlhw = sig.rlhe*P.kvlh;
            sig.mlhe = sig.mlhw + P.kmlhm*P.kslhm*sig.tlhme/sig.hlhe;
            sig.mhhw = sig.rhhe*P.kvhh;
            sig.mhhe = sig.mhhw + P.kmhhm*P.kshhm*sig.thhme/sig.hhhe;
            % air and gas densities at the fans (constants in the thesis)
            sig.rahao = 0.0661;
            sig.rapgo = 0.044;
        end

        function sig = vesselBalances(obj, s, sig)
            % Drum and deaerator mass/energy imbalances and vessel dynamics.
            P = obj.par;
            sig.hdrd = sig.hdrs - sig.hdrw;
            sig.hwwo = sig.hrpo + sig.qwwmw/sig.wwwo;
            sig.qyww = (sig.qwwmw + sig.wrw*(sig.hrpo - sig.hdrw))/(sig.wrw*sig.hdrd);
            [sig.wderp, sig.wdewh, sig.wdebd, sig.hderp, sig.hdewh] = ...
                usoro.VesselDynamics.deaeratorSteam(sig.wdrs, sig.whp);
            sig.hdebd = sig.hdes;
            sig.wdrbd = P.kn2*sig.wdebd;
            sig.wdesr = sig.wderp + sig.wdewh + sig.wdebd;
            sig.qdesr = sig.wderp*sig.hderp + sig.wdewh*sig.hdewh + sig.wdebd*sig.hdebd;
            sig.z206 = sig.wfw - sig.wrw + sig.wwwo - sig.wdrs - sig.wdrbd;
            sig.z209 = sig.wwwo*sig.hwwo - (sig.wrw - sig.wfw)*sig.hdrw ...
                - sig.wdrs*sig.hdrs - sig.wdrbd*sig.hdrs;
            sig.z226 = sig.wdvo + sig.whhs + sig.wdex + sig.wdesr - sig.wfp;
            sig.z229 = sig.wdvo*s.hlho + sig.whhs*sig.h3hhso + sig.wdex*sig.hdex ...
                + sig.qdesr - sig.wfp*sig.hdew;
            [sig.f1dr, sig.f2dr] = usoro.VesselDynamics.saturatedVessel(P.kvdr, ...
                s.vdrw, s.rdrs, sig.rdrw, sig.hdrw, sig.hdrs, ...
                P.k2, P.k3, P.k5, P.k6, P.k7, P.k9, P.k10, sig.z206, sig.z209);
            [sig.f1de, sig.f2de] = usoro.VesselDynamics.saturatedVessel(P.kvde, ...
                s.vdew, s.rdes, sig.rdew, sig.hdew, sig.hdes, ...
                P.k22, P.k23, P.k25, P.k26, P.k27, P.k29, P.k30, sig.z226, sig.z229);
            sig.wlpo = sig.wlp - sig.wlhst - sig.wdex;
        end

        function sig = machines(obj, s, u, sig)
            % Prime-mover torques, level fits and first-stage pressure.
            P = obj.par;
            [sig.tqrp1, sig.mwrp1] = usoro.Turbomachinery.inductionMotor( ...
                P.nelec, P.velec, P.knrpm, s.nrp, P.krpm, P.srpmax);
            [sig.tqcp1, sig.mwcp1] = usoro.Turbomachinery.inductionMotor( ...
                P.nelec, P.velec, P.kncpm, s.ncp, P.kcpm, P.scpmax);
            [sig.tqfd1, sig.mwfd1] = usoro.Turbomachinery.inductionMotor( ...
                P.nelec, P.velec, P.knfdm, s.nfd, P.kfdm, P.sfdmax);
            [sig.tqid1, sig.mwid1] = usoro.Turbomachinery.inductionMotor( ...
                P.nelec, P.velec, P.knidm, s.nid, P.kidm, P.sidmax);
            sig.hft1 = sig.hcro;
            if sig.wssx > P.kn0
                sig.hft1 = s.hsso;
            end
            [sig.tqfp1, sig.mwfp1] = usoro.Turbomachinery.feedpumpTurbine(u.wft, sig.hft1, s.nfp);
            sig.xdew = P.k1xdew + P.k2xdew*s.vdew + P.k3xdew*s.vdew*s.vdew;
            sig.xdrw = P.k1xdrw + P.k2xdrw*s.vdrw + P.k3xdrw*s.vdrw*s.vdrw;
            sig.phhd = sig.pfpo - sig.phho;
            sig.p1st = P.k1p1st*sig.whp;
        end

        function xdot = physicalDerivatives(obj, s, sig)
            % Physical state derivatives (thesis Appendix A; states 1-22, 47).
            P = obj.par;
            xdot = zeros(47, 1);
            xdot(1) = (sig.tqfp1 - sig.wfp*(sig.pfpo - sig.pdes)*P.kn144/ ...
                (s.nfp*sig.rdew*sig.efp))/P.kjfpe;
            xdot(2) = (sig.wfw*(sig.hfvo - s.hhho) + sig.qhh)/sig.mhhe;
            xdot(3) = (sig.wfw*(s.hhho - s.heco) + sig.qec)/sig.mece;
            xdot(4) = sig.f1dr;                                  % vdrw
            xdot(5) = sig.f2dr;                                  % rdrs
            xdot(6) = (sig.tqrp1 - sig.wrp*(sig.prpo - sig.pdco)*P.kn144/ ...
                (s.nrp*sig.rdc*sig.erp))/P.kjrp;
            xdot(7) = (sig.qwwgm - sig.qwwmw)/(sig.mwwme*P.kswwm);
            xdot(8) = (sig.wdrs - sig.wpso)/P.kvps;              % rpso
            xdot(9) = (sig.wdrs*sig.hdrs - sig.wpso*s.hpso + sig.qps)/sig.mpse;
            xdot(10) = (sig.wss1 - sig.wsso)/P.kvss;
            xdot(11) = (sig.wss1*sig.hss1 - sig.wsso*s.hsso + sig.qss)/sig.msse;
            xdot(12) = (sig.wtv - sig.whp)/P.kvsce;
            xdot(13) = (sig.wrh1 - sig.wiv)/P.kvrh;
            xdot(14) = (sig.wrh1*sig.hrh1 - sig.wiv*s.hrho + sig.qrh)/sig.mrhe;
            xdot(15) = (sig.wipo - sig.wlp)/P.kvcre;
            xdot(16) = (sig.mwtro - sig.mwgn)/(s.ntr*P.kjtre);   % swing equation
            xdot(17) = (sig.tqcp1 - sig.wcp*(sig.pcpo - sig.pcn)*P.kn144/ ...
                (s.ncp*sig.rcno*sig.ecp))/P.kjcp;
            xdot(18) = (sig.wcw*(sig.hcpo - s.hlho) + sig.qlh + P.kqgc)/sig.mlhe;
            xdot(19) = sig.f1de;                                 % vdew
            xdot(20) = sig.f2de;                                 % rdes
            xdot(21) = (sig.tqfd1 - sig.wfd*(sig.pfdo - sig.pahao)*P.kn144/ ...
                (s.nfd*sig.rahao*sig.efd))/P.kjfd;
            xdot(22) = (sig.tqid1 - sig.wid*(sig.pido - sig.papgo)*P.kn144/ ...
                (s.nid*sig.rapgo*sig.eid))/P.kjid;
            xdot(47) = P.kc1gn*(s.ntr - P.nelec);                % power angle
        end
    end

    methods (Static, Access = private)
        function [a, b, c] = avg3(a1, a2, b1, b2, c1, c2)
            % Arithmetic means of three inlet/outlet pairs.  (averag.m)
            a = 0.5*(a1 + a2);
            b = 0.5*(b1 + b2);
            c = 0.5*(c1 + c2);
        end
    end
end
