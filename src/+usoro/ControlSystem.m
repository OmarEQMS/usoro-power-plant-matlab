classdef ControlSystem < handle
%CONTROLSYSTEM Analog control system of the Usoro Digital Model (Ch. IV).
%   Two responsibilities, split to mirror the plant/controller interface:
%
%   actuatorCommands(s)  - converts the actuator-demand states (35-43, 46)
%                          into physical actuator values (valve/vane areas,
%                          spray and fuel flows) through the transducers.
%   derivatives(s,u,sig,ldc) - evaluates the eleven control loops and
%                          returns the derivatives of states 23-46.
%
%   All controller signals live on the normalized 1-5 V scale; xducer
%   converts between physical ranges and that scale with saturation.

    properties (SetAccess = immutable)
        par usoro.Parameters
    end

    properties
        % Rate feedforward terms of the deaerator/reheat/superheat loops.
        % The legacy code stubs these to zero (marked "falta"); they stand
        % for the d/dt compensation signals of the thesis block diagrams.
        fc2dv  (1,1) double = 0
        fcp1st (1,1) double = 0
        fctrho (1,1) double = 0
        fcxgg  (1,1) double = 0
        % Gas recirculation loop enable. The thesis deactivated this loop
        % for Tests 6 and 7 ("the system took a much longer time to settle
        % ... occasionally put under manual control", p. 58).
        gasRecircEnabled (1,1) logical = true
    end

    methods
        function obj = ControlSystem(par)
            arguments
                par (1,1) usoro.Parameters = usoro.Parameters()
            end
            obj.par = par;
        end

        function u = actuatorCommands(obj, s)
            %ACTUATORCOMMANDS Physical actuator values from the demand states.
            %   Also returns the limited copies of the demand states, which
            %   the demand-lag derivatives use as their feedback terms.
            P = obj.par;
            xd = @usoro.ControlSystem.xducer;
            u.card = usoro.ControlSystem.limchk(s.card);
            u.avf = xd(P.kcl, P.kcu, P.kavl, P.kavu, u.card);
            u.cfld = usoro.ControlSystem.limchk(s.cfld);
            u.wfl = xd(P.kcl, P.kcu, P.kwfll, P.kwflu, u.cfld);
            u.cfnd = usoro.ControlSystem.limchk(s.cfnd);
            u.avi = xd(P.kcl, P.kcu, P.kavl, P.kavu, u.cfnd);
            % gas recirculation demand is ceiling-limited by the fuel flow
            u.cgrd = usoro.ControlSystem.limchk(s.cgrd);
            kwgr = P.kc2gr*u.wfl;
            kcwgr = xd(P.kwgrl, P.kwgru, P.kcl, P.kcu, kwgr);
            u.cgrd = usoro.ControlSystem.check(u.cgrd, kcwgr, P.kcl);
            u.wgr = xd(P.kcl, P.kcu, P.kwgrl, P.kwgru, u.cgrd);
            u.cftd = usoro.ControlSystem.limchk(s.cftd);
            u.wft = xd(P.kcl, P.kcu, P.kwftl, P.kwftu, u.cftd);
            u.cfwd = usoro.ControlSystem.limchk(s.cfwd);
            u.afv = xd(P.kcl, P.kcu, P.kavl, P.kavu, u.cfwd);
            u.cdwd = usoro.ControlSystem.limchk(s.cdwd);
            u.adv = xd(P.kcl, P.kcu, P.kavl, P.kavu, u.cdwd);
            u.cxggd = usoro.ControlSystem.limchk(s.cxggd);
            cry = P.kc1ry*u.cxggd;
            u.wry = xd(P.kcryl, P.kcryu, P.kwryl, P.kwryu, cry);
            u.xgg = xd(P.kcl, P.kcu, P.kxggl, P.kxggu, u.cxggd);
            u.zxgg = u.xgg*57.3;
            u.csyd = usoro.ControlSystem.limchk(s.csyd);
            csy = u.csyd*P.kc4sy;
            u.wsy = xd(P.kcsyl, P.kcsyu, P.kwsyl, P.kwsyu, csy);
            u.agv = xd(P.kn0, P.kn5, P.kavl, P.kavu, s.cacvd);
            u.atv = 1.0;
            u.aiv = 1.0;
        end

        function xdot = derivatives(obj, s, u, sig, ldc)
            %DERIVATIVES Control-state derivatives (states 23-46).
            P = obj.par;
            xd = @usoro.ControlSystem.xducer;
            lim = @usoro.ControlSystem.limchk;
            chk = @usoro.ControlSystem.check;
            xdot = zeros(47, 1);

            % boiler master demand (throttle pressure control)
            kpsso = P.k1pss + P.k2pss*ldc;
            kpsso = chk(kpsso, P.k4pss, P.k3pss); %#ok<NASGU> % scheduled set point,
            kpsso = P.k4pss;    % overridden: fixed 2415 psia (boiler-following mode)
            kcpsso = xd(P.kpssol, P.kpssou, P.kcl, P.kcu, kpsso);
            cpsso = xd(P.kpssol, P.kpssou, P.kcl, P.kcu, sig.psso);
            c1md = kcpsso - cpsso;
            c2md = c1md*P.kc1md;
            c3md = lim(s.c3md);
            c4md = c2md + c3md;
            c4md = lim(c4md);
            cntr = xd(P.kntrl, P.kntru, P.kcl, P.kcu, s.ntr);
            kcntr = xd(P.kntrl, P.kntru, P.kcl, P.kcu, P.kntr);
            c5md = P.kc2md*(kcntr - cntr);
            cbmd = c4md + c5md;
            cbmd = lim(cbmd);

            % air flow control (cross-limited with fuel demand: takes the max)
            cwar = xd(P.kwarl, P.kwaru, P.kcl, P.kcu, sig.war);
            cwfl = u.cfld;
            c2ar = cbmd;
            if cwfl > cbmd
                c2ar = cwfl;
            end
            if c2ar < P.kc2arl
                c2ar = P.kc2arl;
            end
            c3ar = c2ar - cwar;
            c4ar = c3ar*P.kc1ar;
            c5ar = lim(s.c5ar);
            c6ar = c4ar + c5ar;
            c6ar = lim(c6ar);

            % fuel flow control (cross-limited with measured air: takes the min)
            c2fl = cbmd;
            if cwar < cbmd
                c2fl = cwar;
            end
            c3fl = c2fl - cwfl;
            c4fl = c3fl*P.kc1fl;
            c5fl = lim(s.c5fl);
            c6fl = c4fl + c5fl;
            c6fl = lim(c6fl);

            % furnace pressure control
            cpfn = xd(P.kpfnl, P.kpfnu, P.kcl, P.kcu, sig.pfn);
            kcpfn = xd(P.kpfnl, P.kpfnu, P.kcl, P.kcu, P.kpfn);
            c1fn = kcpfn - cpfn;
            c2fn = c1fn*P.kc1fn;
            c3fn = lim(s.c3fn);
            c4fn = c2fn + c3fn;
            c4fn = lim(c4fn);
            c5fn = c4fn + P.kc2fn*cwar;
            c5fn = lim(c5fn);

            % gas recirculation control (enabled beyond the tilt deadband)
            kcgr = P.kn0;
            if obj.gasRecircEnabled && abs(u.xgg) > P.knp087
                kcgr = P.kn1;
            end
            c1gr = u.cxggd - P.kcxgg;
            c2gr = lim(s.c2gr);

            % boiler feedpump control (feedwater valve differential pressure)
            cpfvd = xd(P.kpfvdl, P.kpfvdu, P.kcl, P.kcu, sig.pfvd);
            kcpfvd = xd(P.kpfvdl, P.kpfvdu, P.kcl, P.kcu, P.kpfvd);
            c1ft = P.kc1ft*(kcpfvd - cpfvd);
            c2ft = lim(s.c2ft);
            c3ft = c1ft + c2ft;
            c3ft = lim(c3ft);

            % feedwater control (three-element: level, steam flow, feed flow)
            zwfw = sig.wfw + u.wsy;
            cwfw = xd(P.kwfwl, P.kwfwu, P.kcl, P.kcu, zwfw);
            cp1st = xd(P.kp1stl, P.kp1stu, P.kcl, P.kcu, sig.p1st);
            cxdrw = xd(P.kxdrwl, P.kxdrwu, P.kcl, P.kcu, sig.xdrw);
            kcxdrw = xd(P.kxdrwl, P.kxdrwu, P.kcl, P.kcu, P.kxdrw);
            cpdrs = xd(P.kpdrsl, P.kpdrsu, P.kcl, P.kcu, sig.pdrs);
            c1fv = cxdrw + P.kc4fv*cpdrs;
            c2fv = P.kc1fv*(kcxdrw - c1fv);
            c3fv = chk(s.c3fv, P.kn5, P.km5);
            c4fv = c2fv + c3fv;
            c4fv = chk(c4fv, P.kn5, P.km5);
            c5fv = P.kc2fv*(cp1st - cwfw);
            c6fv = P.kc3fv*(c4fv + c5fv);
            c7fv = lim(s.c7fv);
            c8fv = c6fv + c7fv;
            c8fv = lim(c8fv);

            % deaerator level control (condensate flow)
            cprho = xd(P.kprhol, P.kprhou, P.kcl, P.kcu, sig.prho);
            cwcw = xd(P.kwcwl, P.kwcwu, P.kcl, P.kcu, sig.wcw);
            cxdew = xd(P.kxdewl, P.kxdewu, P.kcl, P.kcu, sig.xdew);
            kcxdew = xd(P.kxdewl, P.kxdewu, P.kcl, P.kcu, P.kxdew);
            c1dv = kcxdew - cxdew;
            c2dv = c1dv*P.kc1dv;
            c3dv = chk(s.c3dv, P.kn5, P.km5);
            c4dv = P.ktc2dv*obj.fc2dv;
            c5dv = c2dv + c3dv + c4dv;
            c5dv = chk(c5dv, P.kn5, P.km5);
            c6dv = P.kc4dv*cprho - P.kc5dv*cwcw;
            c7dv = P.kc2dv*(c5dv + P.kc6dv*c6dv);
            c8dv = lim(s.c8dv);
            c9dv = c7dv + c8dv;
            c9dv = lim(c9dv);

            % reheat temperature control (burner tilt)
            ctrho = xd(P.ktrhol, P.ktrhou, P.kcl, P.kcu, sig.trho);
            ktrh = P.k1trh + P.k2trh*sig.whp;
            ktrh = chk(ktrh, P.k4trh, P.k3trh);
            kctrh = xd(P.ktrhol, P.ktrhou, P.kcl, P.kcu, ktrh);
            c1rh = kctrh;
            c2rh = obj.fcp1st*P.kc3rh;
            c3rh = c1rh + c2rh - ctrho;
            c4rh = c3rh*P.kc1rh;
            c5rh = lim(s.c5rh);
            c6rh = c4rh + c5rh;
            c6rh = lim(c6rh);
            c7rh = obj.fctrho*P.kc2rh;
            c8rh = c6rh + c7rh;
            c8rh = lim(c8rh);
            cxgg = c8rh;

            % superheat temperature control (desuperheater spray)
            ktss = P.k1tss + P.k2tss*sig.whp;
            ktss = chk(ktss, P.k4tss, P.k3tss);
            ctsso = xd(P.ktssol, P.ktssou, P.kcl, P.kcu, sig.tsso);
            kctss = xd(P.ktssol, P.ktssou, P.kcl, P.kcu, ktss);
            c2sy = kctss;
            c3sy = c2sy - ctsso;
            c4sy = c3sy*P.kc1sy;
            c5sy = lim(s.c5sy);
            c6sy = c4sy + c5sy;
            c6sy = lim(c6sy);
            c7sy = obj.fcp1st*P.kc2sy;
            c8sy = obj.fcxgg*P.kc3sy;
            c9sy = c6sy + c7sy + c8sy;
            c9sy = lim(c9sy);
            cwsy = c9sy;

            % turbine control (load reference + governor droop)
            cmwtro = xd(P.kmwtrl, P.kmwtru, P.kn0, P.kn6, sig.mwtro);
            cmwgn = xd(P.kmwtrl, P.kmwtru, P.kn0, P.kn6, sig.mwgn); %#ok<NASGU>
            cntre = kcntr - cntr;
            c1tr = P.kc1tr*(ldc - cmwtro);
            c2tr = chk(s.c2tr, P.kn1, P.km1);
            c3tr = c1tr + c2tr + ldc;
            c3tr = chk(c3tr, P.kn5, P.kn0);
            c4tr = chk(s.c4tr, P.kn5, P.kn0);
            c5tr = P.kc2tr*cntre;
            c6tr = c5tr/P.kcvreg + c4tr;
            c6tr = chk(c6tr, P.kn5, P.kn0);
            cacvd = chk(s.cacvd, P.kn5, P.kn0);

            % integrator and demand-lag derivatives (states 23-46)
            xdot(23) = c2md/P.ktc1md;
            xdot(24) = c4ar/P.ktc1ar;
            xdot(25) = c4fl/P.ktc1fl;
            xdot(26) = c2fn/P.ktc1fn;
            xdot(27) = c1gr*P.kc1gr*kcgr;
            xdot(28) = c1ft/P.ktc1ft;
            xdot(29) = c2fv/P.ktc1fv;
            xdot(30) = c6fv/P.ktc2fv;
            xdot(31) = c2dv/P.ktc1dv;
            xdot(32) = c7dv/P.ktc3dv;
            xdot(33) = c4rh/P.ktc1rh;
            xdot(34) = c4sy/P.ktc1sy;
            xdot(35) = (c6ar - u.card)/P.ktc2ar;
            xdot(36) = (c6fl - u.cfld)/P.ktc2fl;
            xdot(37) = (c5fn - u.cfnd)/P.ktc2fn;
            xdot(38) = (c2gr - u.cgrd)/P.ktc1gr;
            xdot(39) = (c3ft - u.cftd)/P.ktc2ft;
            xdot(40) = (c8fv - u.cfwd)/P.ktc3fv;
            xdot(41) = (c9dv - u.cdwd)/P.ktc4dv;
            xdot(42) = (cxgg - u.cxggd)/P.ktc2rh;
            xdot(43) = (cwsy - u.csyd)/P.ktc2sy;
            xdot(44) = c1tr/P.ktc1tr;
            xdot(45) = (c3tr - c4tr)/P.ktc2tr;
            xdot(46) = (c6tr - cacvd)/P.ktc3tr;
        end
    end

    methods (Static)
        function c = xducer(zmin, zmax, cmin, cmax, z)
            % Linear transducer with saturation.  (xducer.m)
            c = cmin + (cmax - cmin)*(z - zmin)/(zmax - zmin);
            if c < cmin
                c = cmin;
            end
            if c > cmax
                c = cmax;
            end
        end

        function zc = limchk(zc)
            % Clamp a controller signal to the 1-5 V range.  (limchk.m)
            if zc < 1
                zc = 1;
            end
            if zc > 5
                zc = 5;
            end
        end

        function zc = check(zc, zmax, zmin)
            % Clamp to [zmin, zmax] (legacy argument order).  (check.m)
            if zc < zmin
                zc = zmin;
            end
            if zc > zmax
                zc = zmax;
            end
        end
    end
end
