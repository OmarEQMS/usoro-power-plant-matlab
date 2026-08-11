% Prueba 1, Digital Model, Usoro47, MIT, 1977, pba1.m
% "A drum boiler-turbine power plant under emergency 
% state control" eqm 10jun'24, orden=47
%--------------------------------------------------------
% read variables from file
clear
close all
format short e
global dxdt
diginit100
const1
const2
const3
% Miscellanous initializations
t = -Ts; xdot=zeros(47,1);
%--------------------------------------------------------
%---------         >>>   MAIN LOOP   <<<           ------
%--------------------------------------------------------
for i=1:samples
  t = t + Ts;
  if(t>=10 && t<=100)           % t<=100 /120
      ldc=5-0.0125*(t-10);    % ldc=3.875+0.0125*(t-10);
  end
% jc=jc+1;
%----------------falta---------------
fc2dv=0;%(c2dv-c2dv0)/tstep;
fcp1st=0;%(cp1st-cp1st0)/tstep;
fctrho=0;%(ctrho-ctrho0)/tstep;
fcxgg=0;%(cxgg-cxgg0)/tstep;
% c2dvd=c2dv;
% cp1st0=cp1st;
% ctrho0=ctrho;
% cxgg0=cxgg;
% set controlled input values
card=limchk(card);
avf=xducer(kcl,kcu,kavl,kavu,card);
cfld=limchk(cfld);
wfl=xducer(kcl,kcu,kwfll,kwflu,cfld);
cfnd=limchk(cfnd);
avi=xducer(kcl,kcu,kavl,kavu,cfnd);
cgrd=limchk(cgrd);
kwgr=kc2gr*wfl;
kcwgr=xducer(kwgrl,kwgru,kcl,kcu,kwgr);
cfld=limchk(cfld);
cgrd=check(cgrd,kcwgr,kcl);
wgr=xducer(kcl,kcu,kwgrl,kwgru,cgrd);
cftd=limchk(cftd);
wft=xducer(kcl,kcu,kwftl,kwftu,cftd);
cfwd=limchk(cfwd);
afv=xducer(kcl,kcu,kavl,kavu,cfwd); %afv=0.9;
cdwd=limchk(cdwd);
adv=xducer(kcl,kcu,kavl,kavu,cdwd);
cxggd=limchk(cxggd);
cry=kc1ry*cxggd; %d
wry=xducer(kcryl,kcryu,kwryl,kwryu,cry);
xgg=xducer(kcl,kcu,kxggl,kxggu,cxggd);
zxgg=xgg*57.3;
csyd=limchk(csyd);
csy=csyd*kc4sy;
wsy=xducer(kcsyl,kcsyu,kwsyl,kwsyu,csy);
agv=xducer(kn0,kn5,kavl,kavu,cacvd);
atv=1.0;
aiv=1.0;
% state properties
[rdrw,hdrw,hdrs,pdrs,tdrs]=drstat(rdrs);
[rdew,hdew,hdes,pdes,tdes]=destat(rdes);
[ppso,tpso,spso]=shstat(rpso,hpso);
[psso,tsso,ssso]=shstat(rsso,hsso);
[psco,tsco,ssco]=shstat(rsco,hsso);
[prho,trho,srho]=rhstat(rrho,hrho);
[reco,teco]=fwstat(heco,pdrs);
[rdvo,tdvo]=cwstat(hlho,pdes);
% steam flow
ppsd=pdrs-ppso;
[wdrs]=shflow(rdrs,ppsd,kfps);
acv=agv;
wtv=kcv*acv*sqrt(psso*rsso);
wpsx=kn0;
if(wtv<kwtv) % 100% wtv=1.1093e+03, kwtv=5.0670e+02
  wpsx=(101.56064-0.39882*wdrs+4.8626e-4*wdrs*wdrs); %.5
end
pssd=ppso-psso;
[wss1]=shflow(rsso,pssd,kfss);
wpso=wss1+wpsx-wsy;
whp=khp*sqrt(rsco*psco); %whp=1109.2; %para pba
wssx=kn0;
if(wtv<kwtv); wssx=wft; end
wsso=wtv+wssx; %
[whpaux,w1hhs]=hpext(whp);
whpo=whp-whpaux-w1hhs;
wrh1=whpo+wry;
wiv=kip*aiv*sqrt(rrho*prho);
wip=wiv;
% turbine
ehp=0.589+2.317e-4*whp;
phpo=prho+kfrh*wip*wip/rrho;
[hhpo,thpo]=hpstat(ssso,phpo,ehp,hsso);
eip=0.814;
[hcro,pcro,tcro]=crstat(srho,rcro,eip,hrho);
wlp=klp*sqrt(rcro*pcro);
pcn=k0pcn+k1pcn*pcro+k2pcn*pcro*pcro;
qylpo=kqylpo;
[hlpo,rlpo,slpo,tcn,rcno,hcno]=cnstat(pcn,qylpo);
mwhp=whp*(hsso-hhpo)*kj;
keip=0.93;
kelp=0.93;
mwip=wip*(hrho-hcro)*kj*keip;
mwlp=wlp*(hcro-hlpo)*kj*kelp;
mwtro=mwhp+mwip+mwlp;
mwo=mwtro*kmwx;
mwgnpu=kn2*sin(delta);
mwgn=mwgnpu*kmwr;
mwtrpu=mwtro/kmwr;
[w2hhs,w3hhs,h2hhs1,p2hhs,p3hhso]=...
    ipext(wip,prho,pcro,hrho,hcro);
wipftx=wft;
if(wssx>kn0); wipftx=kn0; end
wipo=wip-w2hhs-w3hhs-wipftx;
% water side
[wcw,wcp,pcpo,plho,wlhx,wdvo,ecp]=cwflow...
(pcn,rcno,rdvo,pdes,ncp,adv,kncp); %
[hcpo,tcpo]=cpstat(rcno,pcpo);
[rlho,tlho]=cwstat(hlho,plho);
%if(t<0.11)
[wfp,wfw,wfw2,pbpo,pfpo,pfvo,phho,pfvd,efp]=fwflow...
(wry,wsy,rdew,pdes,pdrs,reco,afv,nfp);
%end
[hfpo,tfpo]=fpstat(rdew,pfpo);
hfvo=hfpo;
[rhho,thho]=fwstat(hhho,phho);
rdc=rdrw;
%if(t<0.11)
[wrw,wrp,wwwo,pdco,prpo,erp]=rwflow...
    (knrp,rdc,rdrw,nrp,pdrs);
%end
% heat balance in downcomers, superheat and rehet sprays
hdc1=(wfw*heco+hdrw*(wrw-wfw))/wrw;
hss1=((wpso-wpsx)*hpso+wsy*hfpo)/wss1;
hrh1=(whpo*hhpo+wry*hfpo)/wrh1;
[rdc1,tdc1]=fwstat(hdc1,pdrs);
[hdco,tdco,sdco]=rwstat(rdc1,pdco);
[hrpo,trco,srpo]=rwstat(rdc1,prpo);
[rss1,tss1,sss1]=systat(hss1,ppso);
[rrh1,trh1rh1,s]=rystat(hrh1,phpo);
% feedwater heater steam
[w1lhs,w2lhs,wdex,wlhst,p1lhs,p2lhs,p3lhs,h1lhs1,h2lhs1,...
    hdex]=lpext(wlp,pcro,pcn,hcro,hlpo);
[h1lhso,r1lhso,t1lhso]=lsstat(p1lhs);
[h2lhso,r2lhso,t2lhso]=lwstat(p2lhs);
[h3lhso,r3lhso,t3lhso]=lwstat(p3lhs);
qlh=w1lhs*(h1lhs1-h3lhso)+w2lhs*(h2lhs1-h2lhso);
whhst=w1hhs+w2hhs+w3hhs;
[h3hhso,r3hhso,t3hhso]=lsstat(p3hhso);
qhh=w1hhs*hhpo+w2hhs*h2hhs1+w3hhs*hcro-whhst*h3hhso; %
whhs=whhst;
if(wfw<kwfw); whhs=kn0; end
% mean flow, temperature, density, and enthalpy
[wpse,rpse,hpse]=averag(wdrs,wpso,rdrs,rpso,hdrs,hpso);
[wsse,rsse,hsse]=averag(wss1,wsso,rss1,rsso,hss1,hsso);
[wrhe,rrhe,hrhe]=averag(wrh1,wip,rrh1,rrho,hrh1,hrho);
[pece,hece,plhe]=averag(phho,pdrs,hhho,heco,pcpo,plho);
[phhe,hhhe,hlhe]=averag(pfvo,phho,hfvo,hhho,hcpo,hlho);
[ppse,tpse,spse]=shstat(rpse,hpse);
[psse,tsse,ssse]=shstat(rsse,hsse);
[prhe,trhe,srhe]=rhstat(rrhe,hrhe);
[rece,tece]=fwstat(hece,pece);
[rhhe,thhe]=fwstat(hhhe,phhe);
[rlhe,tlhe]=cwstat(hlhe,plhe);
% air and gas flow
%if(t<0.11)
[war,wwwg,wfd,wgo,wid,pahao,pfdo,pfn,pecgo,papgo,pido,...
    efd,eid]=arflow(knfd,knid,nfd,nid,wgr,wfl,avf,avi);
%end
% air side heat transfer
tahao=ktat+ktahad;
tapao=tahao+ktapad;
ward=kafr*wfl;
% furnace
% burner tilt correction factor
uxgg=k1xgg+k2xgg*sin(xgg)/cos(xgg);
% number of operating guns
ngg=ng1+ng2+ng3+ng4+ng5;
ungg=(ng1*k1ng+ng2*k2ng+ng3*k3ng+ng4*k4ng+ng5*k5ng)/...
    (ngg*kxwwe);
uwwgm=kuwwgm*uxgg*ungg;
tgr=k1tgr+k2tgr*wfl;
[tfn1,twwge,twwgo,qwwgm,qpsr,swwgo]=fnxfer(twwm,wwwg,war,...
sar,tapao,wfl,sfl,tfl,khfl,efl,wgr,sgr,tgr,uwwgm,ywgr,...
tpse,kupsr);
qwwmw=kuwwmw*(twwm-tdrs)^3;
% gas side heat transfer
qssr=kn0;
qrhr=kn0;
qecr=kn0;
[tpsgo,qps,tpsme,spsgo]=hxfer...
    (wwwg,wpse,kupsgm,kupsms,tpse,twwgo,qpsr,ywgr);
[tssgo,qss,tssme,sssgo]=hxfer...
    (wwwg,wsse,kussgm,kussms,tsse,tpsgo,qssr,ywgr);
[trhgo,qrh,trhme,srhgo]=hxfer...
    (wwwg,wrhe,kurhgm,kurhms,trhe,tssgo,qrhr,ywgr);
[tecgo,qec,tecme,secgo]=hxfer...
    (wwwg,wfw,kuecgm,kuecmw,tece,trhgo,qecr,ywgr);
tlhme=klhm*tlho;
thhme=khhm*thho;
% effective masses
mwwme=kmwwm+kvww*rdrw*hdrw/(kswwm*twwm);
mpss=rpse*kvps;
mpse=mpss+kmpsm*kspsm*tpsme/hpse;
msss=rsse*kvss;
msse=msss+kmssm*ksssm*tssme/hsse;
mrhs=rrhe*kvrh;
mrhe=mrhs+kmrhm*ksrhm*trhme/hrhe;
mecw=rece*kvec;
mece=mecw+kmecm*ksecm*tecme/hece;
mlhw=rlhe*kvlh;
mlhe=mlhw+kmlhm*kslhm*tlhme/hlhe;
mhhw=rhhe*kvhh;
mhhe=mhhw+kmhhm*kshhm*thhme/hhhe;
% air and gas densities
rahao=0.0661;
rapgo=0.044;
% drum intermediate variables
% deaerator intermediate variables
hdrd=hdrs-hdrw;
hwwo=hrpo+qwwmw/wwwo;
qyww=(qwwmw+wrw*(hrpo-hdrw))/(wrw*hdrd);
[wderp,wdewh,wdebd,hderp,hdewh]=destmr(wdrs,whp);
hdebd=hdes;
wdrbd=kn2*wdebd;
wdesr=wderp+wdewh+wdebd;
qdesr=wderp*hderp+wdewh*hdewh+wdebd*hdebd;
z206=wfw-wrw+wwwo-wdrs-wdrbd;
z209=wwwo*hwwo-(wrw-wfw)*hdrw-wdrs*hdrs-wdrbd*hdrs;
z226=wdvo+whhs+wdex+wdesr-wfp;
z229=wdvo*hlho+whhs*h3hhso+wdex*hdex+qdesr-wfp*hdew;
%if(t<0.1)
[f1dr,f2dr]=drum(kvdr,vdrw,rdrs,rdrw,hdrw,hdrs,...
    k2,k3,k5,k6,k7,k9,k10,z206,z209);
%end
%if(t<0.11)
[f1de,f2de]=drum(kvde,vdew,rdes,rdew,hdew,hdes,...
    k22,k23,k25,k26,k27,k29,k30,z226,z229);
%end
wlpo=wlp-wlhst-wdex;
% pump and fan input torque
[tqrp1,mwrp1]=torque(nelec,velec,knrpm,nrp,krpm,srpmax);
[tqcp1,mwcp1]=torque(nelec,velec,kncpm,ncp,kcpm,scpmax);
[tqfd1,mwfd1]=torque(nelec,velec,knfdm,nfd,kfdm,sfdmax);
[tqid1,mwid1]=torque(nelec,velec,knidm,nid,kidm,sidmax);
hft1=hcro;
if(wssx>kn0); hft1=hsso; end
[tqfp1,mwfp1]=fpturb(wft,hft1,nfp);
xdew=k1xdew+k2xdew*vdew+k3xdew*vdew*vdew;
xdrw=k1xdrw+k2xdrw*vdrw+k3xdrw*vdrw*vdrw; %xdrw=2.5346e-03;
phhd=pfpo-phho;
p1st=k1p1st*whp; 
% control system
% boiler master demand (#364) dif=130
kpsso=k1pss+k2pss*ldc; %unused
kpsso=check(kpsso,k4pss,k3pss); %
kpsso=k4pss;
kcpsso=xducer(kpssol,kpssou,kcl,kcu,kpsso);
cpsso=xducer(kpssol,kpssou,kcl,kcu,psso);
c1md=kcpsso-cpsso;
c2md=c1md*kc1md;
c3md=limchk(c3md); %23
c4md=c2md+c3md;
c4md=limchk(c4md);
cntr=xducer(kntrl,kntru,kcl,kcu,ntr);
kcntr=xducer(kntrl,kntru,kcl,kcu,kntr);
c5md=kc2md*(kcntr-cntr);
cbmd=c4md+c5md;
cbmd=limchk(cbmd);
% air flow control
cwar=xducer(kwarl,kwaru,kcl,kcu,war);
cwfl=cfld; %=36
c2ar=cbmd;
if(cwfl>cbmd); c2ar=cwfl; end
if(c2ar<kc2arl); c2ar=kc2arl; end
c3ar=c2ar-cwar;
c4ar=c3ar*kc1ar; %
c5ar=limchk(c5ar); %24
c6ar=c4ar+c5ar;
c6ar=limchk(c6ar); % --> 35 retardo
% fuel flow control
c2fl=cbmd;
if(cwar<cbmd); c2fl=cwar; end
c3fl=c2fl-cwfl;
c4fl=c3fl*kc1fl;
c5fl=limchk(c5fl); %25
c6fl=c4fl+c5fl;
c6fl=limchk(c6fl); % --> 35 retardo
% furnace pressure control
cpfn=xducer(kpfnl,kpfnu,kcl,kcu,pfn);
kcpfn=xducer(kpfnl,kpfnu,kcl,kcu,kpfn);
c1fn=kcpfn-cpfn;
c2fn=c1fn*kc1fn;
c3fn=limchk(c3fn);
c4fn=c2fn+c3fn;
c4fn=limchk(c4fn);
c5fn=c4fn+kc2fn*cwar; 
c5fn=limchk(c5fn); % --> 37 retardo
% gas recirculation control
kcgr=kn0;
if(abs(xgg)>knp087); kcgr=kn1; end
c1gr=cxggd-kcxgg;
c2gr=limchk(c2gr); %27
% boiler feedpump control
cpfvd=xducer(kpfvdl,kpfvdu,kcl,kcu,pfvd);
kcpfvd=xducer(kpfvdl,kpfvdu,kcl,kcu,kpfvd);
c1ft=kc1ft*(kcpfvd-cpfvd);
c2ft=limchk(c2ft); %28
c3ft=c1ft+c2ft;
c3ft=limchk(c3ft);
% feedwater control
zwfw=wfw+wsy;
cwfw=xducer(kwfwl,kwfwu,kcl,kcu,zwfw);
cp1st=xducer(kp1stl,kp1stu,kcl,kcu,p1st);
cxdrw=xducer(kxdrwl,kxdrwu,kcl,kcu,xdrw); %cxdrw=3;
kcxdrw=xducer(kxdrwl,kxdrwu,kcl,kcu,kxdrw);
cpdrs=xducer(kpdrsl,kpdrsu,kcl,kcu,pdrs);
c1fv=cxdrw+kc4fv*cpdrs; %kc4fv=0
c2fv=kc1fv*(kcxdrw-c1fv);
c3fv=check(c3fv,kn5,km5); %29
c4fv=c2fv+c3fv;
c4fv=check(c4fv,kn5,km5);
c5fv=kc2fv*(cp1st-cwfw); %kc2fv=1
c6fv=kc3fv*(c4fv+c5fv);
c7fv=limchk(c7fv); %30
c8fv=c6fv+c7fv;
c8fv=limchk(c8fv);
% deaerator level control
cprho=xducer(kprhol,kprhou,kcl,kcu,prho);
cwcw=xducer(kwcwl,kwcwu,kcl,kcu,wcw);
cxdew=xducer(kxdewl,kxdewu,kcl,kcu,xdew);
kcxdew=xducer(kxdewl,kxdewu,kcl,kcu,kxdew); %
c1dv=kcxdew-cxdew;
c2dv=c1dv*kc1dv;
c3dv=check(c3dv,kn5,km5); %31
c4dv=ktc2dv*fc2dv;
c5dv=c2dv+c3dv+c4dv;
c5dv=check(c5dv,kn5,km5);
c6dv=kc4dv*cprho-kc5dv*cwcw;
c7dv=kc2dv*(c5dv+kc6dv*c6dv);
c8dv=limchk(c8dv); %32
c9dv=c7dv+c8dv;
c9dv=limchk(c9dv);
% reheat temperature control
ctrho=xducer(ktrhol,ktrhou,kcl,kcu,trho);
ktrh=k1trh+k2trh*whp;
ktrh=check(ktrh,k4trh,k3trh);
kctrh=xducer(ktrhol,ktrhou,kcl,kcu,ktrh);
c1rh=kctrh;
c2rh=fcp1st*kc3rh;
c3rh=c1rh+c2rh-ctrho;
c4rh=c3rh*kc1rh;
c5rh=limchk(c5rh); %33
c6rh=c4rh+c5rh;
c6rh=limchk(c6rh);
c7rh=fctrho*kc2rh;
c8rh=c6rh+c7rh;
c8rh=limchk(c8rh);
cxgg=c8rh;
% superheat temperature control
ktss=k1tss+k2tss*whp;
ktss=check(ktss,k4tss,k3tss);
ctsso=xducer(ktssol,ktssou,kcl,kcu,tsso);
kctss=xducer(ktssol,ktssou,kcl,kcu,ktss);
c2sy=kctss;
c3sy=c2sy-ctsso;
c4sy=c3sy*kc1sy;
c5sy=limchk(c5sy);
c6sy=c4sy+c5sy;
c6sy=limchk(c6sy);
c7sy=fcp1st*kc2sy;
c8sy=fcxgg*kc3sy;
c9sy=c6sy+c7sy+c8sy;
c9sy=limchk(c9sy);
cwsy=c9sy;
% turbine control
cmwtro=xducer(kmwtrl,kmwtru,kn0,kn6,mwtro);
cmwgn=xducer(kmwtrl,kmwtru,kn0,kn6,mwgn);
cntre=kcntr-cntr;
c1tr=kc1tr*(ldc-cmwtro);
c2tr=check(c2tr,kn1,km1); %44
c3tr=c1tr+c2tr+ldc;
c3tr=check(c3tr,kn5,kn0);
c4tr=check(c4tr,kn5,kn0); %45
c5tr=kc2tr*cntre;
c6tr=c5tr/kcvreg+c4tr;
c6tr=check(c6tr,kn5,kn0);
cacvd=check(cacvd,kn5,kn0); %46
% dynamic equations
% calculate F of Y
% equivalence
% x0=[nfp, hhho, heco, vdrw, rdrs,...  %1-5
%     nrp, twwm, rpso, hpso, rsso,...  %6-10
%     hsso, rsco, rrho, hrho, rcro,... %11-15
%     ntr, ncp, hlho, vdew, rdes,...   %16-20
%     nfd, nid, c3md, c5ar, c5fl,...   %21-25
%     c3fn, c2gr, c2ft, c3fv, c7fv,... %26-30
%     c3dv, c8dv, c5rh, c5sy, card,... %31-35
%     cfld, cfnd, cgrd, cftd, cfwd,... %36-40
%     cdwd, cxggd, csyd, c2tr, c4tr, cacvd, delta]; %47
xdot(1)=0;(tqfp1-wfp*(pfpo-pdes)*kn144/(nfp*rdew*efp))/(kjfpe);
xdot(2)=(wfw*(hfvo-hhho)+qhh)/mhhe;
xdot(3)=(wfw*(hhho-heco)+qec)/mece;
xdot(4)=f1dr; % vdrw 
xdot(5)=f2dr; % rdrs
xdot(6)=(tqrp1-wrp*(prpo-pdco)*kn144/(nrp*rdc*erp))/kjrp;
xdot(7)=(qwwgm-qwwmw)/(mwwme*kswwm);
xdot(8)=(wdrs-wpso)/kvps; % rpso
xdot(9)=(wdrs*hdrs-wpso*hpso+qps)/mpse; % hpso--psso
xdot(10)=(wss1-wsso)/kvss;
xdot(11)=(wss1*hss1-wsso*hsso+qss)/msse;
xdot(12)=(wtv-whp)/kvsce;
xdot(13)=(wrh1-wiv)/kvrh;
xdot(14)=(wrh1*hrh1-wiv*hrho+qrh)/mrhe;
xdot(15)=(wipo-wlp)/kvcre;
xdot(16)=0;%(mwtro-mwgn)/(ntr*kjtre); % ntr=376.99
xdot(17)=(tqcp1-wcp*(pcpo-pcn)*kn144/(ncp*rcno*ecp))/kjcp;
xdot(18)=(wcw*(hcpo-hlho)+qlh+kqgc)/mlhe;
xdot(19)=f1de; % vdew 
xdot(20)=f2de; % rdes
xdot(21)=(tqfd1-wfd*(pfdo-pahao)*kn144/(nfd*rahao*efd))/kjfd;
xdot(22)=(tqid1-wid*(pido-papgo)*kn144/(nid*rapgo*eid))/kjid;
xdot(23)=c2md/ktc1md;
% for i=24:47
%     xdot(i)=0;
% end
xdot(24)=c4ar/ktc1ar;
xdot(25)=c4fl/ktc1fl;
xdot(26)=c2fn/ktc1fn;
xdot(27)=c1gr*kc1gr*kcgr;
xdot(28)=c1ft/ktc1ft;
xdot(29)=c2fv/ktc1fv;
xdot(30)=c6fv/ktc2fv;
xdot(31)=c2dv/ktc1dv;
xdot(32)=c7dv/ktc3dv;
xdot(33)=c4rh/ktc1rh;
xdot(34)=c4sy/ktc1sy;
xdot(35)=(c6ar-card)/ktc2ar; %retardos 1er orden =5
xdot(36)=(c6fl-cfld)/ktc2fl; %ktc1gr=20
xdot(37)=(c5fn-cfnd)/ktc2fn; %estado cfnd
xdot(38)=(c2gr-cgrd)/ktc1gr;
xdot(39)=(c3ft-cftd)/ktc2ft;
xdot(40)=(c8fv-cfwd)/ktc3fv;
xdot(41)=(c9dv-cdwd)/ktc4dv;
xdot(42)=(cxgg-cxggd)/ktc2rh;
xdot(43)=(cwsy-csyd)/ktc2sy;
xdot(44)=c1tr/ktc1tr;        
xdot(45)=(c3tr-c4tr)/ktc2tr; %retardos 1er orden =1
xdot(46)=(c6tr-cacvd)/ktc3tr;
xdot(47)=kc1gn*(ntr-nelec);
dxdt=xdot;
%-------------------------------------
if(t>=tprint)
  xx2=[xx2;t,ntr,mwo,psso,whp,c3md,cacvd,cfld,card,...
      vdrw,vdew,cfwd,cdwd,hsso,hrho,csyd,cxggd,...
      nfp,cgrd,cfnd,twwm,nfd,nid,nrp,ncp];
%   xx2=[xx2;t,ntr,mwo,psso,wsso,cbmd,cacvd,c6fl,c6ar,...
%       vdrw,vdew,c8fv,c9dv,hsso,hrho,csyd,cxggd,...
%       nfp,c2gr,c5fn,twwm,nfd,nid,nrp,ncp];
% xx2=[xx2;t,ntr,mwo,psso,wsso,c3md,c10tr,c6fl,c6ar,...
%     hsso,hrho,csyd,cxggd,tsso,trho,twwm,cgrd];
    tprint=tprint+1; % graficas de resultados
end
[time,x]=ode45(mat_model,[t-Ts t],x0);
x0 = x(length(time),:)';
%x=x0+xdot*Ts;
xx=[xx;x0'];
% variables de estado
nfp=x0(1); hhho=x0(2); heco=x0(3); vdrw=x0(4); 
rdrs=x0(5); nrp=x0(6); twwm=x0(7); rpso=x0(8); 
hpso=x0(9); rsso=x0(10); hsso=x0(11); rsco=x0(12);
rrho=x0(13); hrho=x0(14); rcro=x0(15); ntr=x0(16); 
ncp=x0(17); hlho=x0(18); vdew=x0(19); rdes=x0(20); 
nfd=x0(21); nid=x0(22); c3md=x0(23); % 23 ss
c5ar=x0(24); c5fl=x0(25); c3fn=x0(26); c2gr=x0(27);
c2ft=x0(28); c3fv=x0(29); c7fv=x0(30); c3dv=x0(31);
c8dv=x0(32); c5rh=x0(33); c5sy=x0(34); card=x0(35);
cfld=x0(36); cfnd=x0(37); cgrd=x0(38); cftd=x0(39);
cfwd=x0(40); cdwd=x0(41); cxggd=x0(42); csyd=x0(43);
c2tr=x0(44); c4tr=x0(45); cacvd=x0(46); delta=x0(47);
end
% (1) p.65 ntr,mwo,psso,wsso
ax1=subplot(221); plot(ax1,xx2(:,1),xx2(:,2));
ax2=subplot(222); plot(ax2,xx2(:,1),xx2(:,3));
ax3=subplot(223); plot(ax3,xx2(:,1),xx2(:,4));
ax4=subplot(224); plot(ax4,xx2(:,1),xx2(:,5));
title(ax1,'ntr'); title(ax2,'mwo'); 
title(ax3,'psso'); title(ax4,'whp');
res=[(1:47)' xx'];
figure % (2) p.66 cbmd,cacvd,c6fl,c6ar
ax1=subplot(221); plot(ax1,xx2(:,1),xx2(:,6));
ax2=subplot(222); plot(ax2,xx2(:,1),xx2(:,7));
ax3=subplot(223); plot(ax3,xx2(:,1),xx2(:,8));
ax4=subplot(224); plot(ax4,xx2(:,1),xx2(:,9));
title(ax1,'c3md'); title(ax2,'cacvd'); 
title(ax3,'cfld'); title(ax4,'card');
figure % (3) p.67 vdrw,vdew,c8fv,c9dv
ax1=subplot(221); plot(ax1,xx2(:,1),xx2(:,10));
ax2=subplot(222); plot(ax2,xx2(:,1),xx2(:,11));
ax3=subplot(223); plot(ax3,xx2(:,1),xx2(:,12));
ax4=subplot(224); plot(ax4,xx2(:,1),xx2(:,13));
title(ax1,'vdrw'); title(ax2,'vdew'); 
title(ax3,'cfwd'); title(ax4,'cdwd');
figure % (4) p.68 hsso,hrho,csyd,cxggd
ax1=subplot(221); plot(ax1,xx2(:,1),xx2(:,14));
ax2=subplot(222); plot(ax2,xx2(:,1),xx2(:,15));
ax3=subplot(223); plot(ax3,xx2(:,1),xx2(:,16));
ax4=subplot(224); plot(ax4,xx2(:,1),xx2(:,17));
title(ax1,'hsso'); title(ax2,'hrho'); 
title(ax3,'csyd'); title(ax4,'cxggd');
figure % (5) p.69 nfp,c2gr,c5fn,twwm
ax1=subplot(221); plot(ax1,xx2(:,1),xx2(:,18));
ax2=subplot(222); plot(ax2,xx2(:,1),xx2(:,19));
ax3=subplot(223); plot(ax3,xx2(:,1),xx2(:,20));
ax4=subplot(224); plot(ax4,xx2(:,1),xx2(:,21));
title(ax1,'nfp'); title(ax2,'cgrd'); 
title(ax3,'cfnd'); title(ax4,'twwm');
figure % (6) p.70 nfd,nid,nrp,ncp
ax1=subplot(221); plot(ax1,xx2(:,1),xx2(:,22));
ax2=subplot(222); plot(ax2,xx2(:,1),xx2(:,23));
ax3=subplot(223); plot(ax3,xx2(:,1),xx2(:,24));
ax4=subplot(224); plot(ax4,xx2(:,1),xx2(:,25));
title(ax1,'nfd'); title(ax2,'nid'); 
title(ax3,'nrp'); title(ax4,'ncp');