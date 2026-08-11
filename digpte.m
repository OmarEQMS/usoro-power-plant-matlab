function xdot=digpte(t,x)
% EDO de la planta termoelectrica, Standard Model, Usoro, MIT, 1977
% "A drum boiler-turbine power plant under emergency state control"
% eqm 14jun'24
%------------------------------------------------------------------
% equivalence
% x0=[nfp, hhho, heco, vdrw, rdrs, nrp, twwm, rpso,...
%     hpso, rsso, hsso, rsco, rrho, hrho, rcro, ntr, ...
%     ncp, hlho, vdew, rdes, nfd, nid, c3md,... % 23 ss
%     c5ar, c5fl, c3fn, c2gr, c2ft, c3fv, c7fv, c3dv,...
%     c8dv, c5rh, c5sy, card, cfld, cfnd, cgrd, cftd,...
%     cfwd, cdwd, cxggd, csyd, c2tr, c4tr, cacvd, delta];
% dynamic equations
global dxdt
xdot=dxdt;
% xdot(1)=(tqfp1-wfp*(pfpo-pdes)*kn144/(nfp*rdew*efp))/kjfpe;
% xdot(2)=(wfw*(hfvo-hhho)+qhh)/mhhe;
% xdot(3)=(wfw*(hhho-heco)+qec)/mecce;
% xdot(4)=f1dr;
% xdot(5)=f2dr;
% xdot(6)=(tqrp1-wrp*(prpo-pdco)*kn144/(nrp*rdc*erp))/kjrp;
% xdot(7)=(qwwgm-qwwmw)/(mwwme*kswwm);
% xdot(8)=(wdrs-wpso)/kvps;
% xdot(9)=(wdrs*hdrs-wpso*hpso+qps)/mpse;
% xdot(10)=(wss1-wsso)/kvss;
% xdot(11)=(wss1*hss1-wsso*hsso+qss)/msse;
% xdot(12)=(wtv-whp)/kvsce;
% xdot(13)=(wrh1-wiv)/kvrh;
% xdot(14)=(wrh1*hrh1-wiv*hrho+qrh)/mrhe;
% xdot(15)=(wipo-wlp)/kvcre;
% xdot(16)=(mwtro-mwgn)/(ntr*kjtrf);
% xdot(17)=(tqcp1-wcp*(pcpo-pcn)*kn144/(ncp*rcno*ecp))/kjcp;
% xdot(18)=(wcw*(hcpo-hlho)+qlh+kqgc)/mlhe;
% xdot(19)=f1de;
% xdot(20)=f2de;
% xdot(21)=(tqfd1-wfd*(pfdo-pahao)*kn144/(nfd*rahao*efd))/kjfd;
% xdot(22)=(tqid1-wid*(pido-papgo)*kn144/(nid*rapgo*eid))/kjid;
% xdot(23)=c2md/ktc1md;
% xdot(24)=c4ar/ktc1ar;
% xdot(25)=c4fl/ktc1fl;
% xdot(26)=c2fn/ktc1fn;
% xdot(27)=c1gr*kc1gr*kcgr;
% xdot(28)=c1ft/ktc1ft;
% xdot(29)=c2fv/ktc1fv;
% xdot(30)=c6fv/ktc2fv;
% xdot(31)=c2dv/ktc1dv;
% xdot(32)=c7dv/ktc3dv;
% xdot(33)=c4rh/ktc1rh;
% xdot(34)=c4sy/ktc1sy;
% xdot(35)=(c6ar-card)/ktc2ar;
% xdot(36)=(c6fl-cfld)/ktc2fl;
% xdot(37)=(c5fn-cfnd)/ktc2fn;
% xdot(38)=(c2gr-cgrd)/ktc1gr;
% xdot(39)=(c3ft-cftd)/ktc2ft;
% xdot(40)=(c8fv-cfwd)/ktc3fv;
% xdot(41)=(c9dv-cdwd)/ktc4dv;
% xdot(42)=(cxgg-cxggd)/ktc2rh;
% xdot(43)=(cwsy-csyd)/ktc2sy;
% xdot(44)=c1tr/ktc1tr;
% xdot(45)=(c3tr-c4tr)/ktc2tr;
% xdot(46)=(c6tr-cacvd)/ktc3tr;
% xdot(47)=kc1gn*(ntr-nelec);
end

