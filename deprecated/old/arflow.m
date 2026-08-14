function [war,wwwg,wfd,wgo,wid,pahao,pfdo,pfn,pecgo,papgo,pido,efd,eid]=...
    arflow(knfd,knid,nfd,nid,wgr,wfl,avf,avi)
% compute air flow
kpat=14.7;
% Fan-curve calibration (mirror of model.Hydraulics.airGas, kept
% identical so validate_against_legacy stays bit-for-bit): x1.10 on the
% fan dP coefficients k1-k3. The printed deck's fans deliver at most
% ~1219 lb/s of air at IC fan speeds with dampers full open, but the
% fuel/air cross-limit needs 1230.0 lb/s to sustain 100% fuel, and the
% thesis's own Table V.1/Fig. V.7 show 1230.3 lb/s at only ~4.55 V of
% air control - the published runs used stronger fans than the printed
% listing. Power terms k4-k6 stay as printed.
kfcal=1.10;
k1fd=-7.41568e-7*kfcal;
k2fd=8.67456e-6*kfcal;
k3fd=1.67206e-4*kfcal;
k4fd=-2.18247e-6;
k5fd=5.13044e-5;
k6fd=-6.96849e-5;
k1id=-1.38148e-6*kfcal;
k2id=1.12227e-5*kfcal;
k3id=1.09727e-4*kfcal;
k4id=-1.12212e-6;
k5id=1.74023e-5;
k6id=3.43528e-5;
kfah=1.82764e-7;
kfapa=3.968e-7;
kfg=263.7944e-9;
kfapg=1.176409e-7;
kfst=2.109e-7;
pstd=7.216667e-2;
nfd2=nfd*nfd;
nid2=nid*nid;
knfd2=knfd*knfd;
knid2=knid*knid;
wfl2=wfl*wfl;
%adf2=adf*adf; % no se usa
%adi2=adi*adi; % no se usa
z1=wfl+wgr;
z2=k1fd/avf;
z4=knfd2*kfapa;
z5=kfah+z4-z2;
z6=kfapg+kfst;
z7=k1id/avi;   %
z9=-z7;
z10=k2fd*nfd;
z11=k2id*nid;
z12=k3fd*nfd2*avf;
z13=k3id*nid2*avi;
z14=z12+z13+pstd;
z15=z9/knid2;
z16=z5+knfd2*(kfg+z6+z15);
z17=2*knfd*(kfg*z1+z6*wfl+z15*wfl)-z10-z11*knfd/knid;
z18=kfg*z1*z1+wfl2*(z6+z15)-z11*wfl/knid-z14;
wfd=0.5*(sqrt(z17*z17-4*z16*z18)-z17)/z16;
war=knfd*wfd;
wwwg=war+z1;
wgo=war+wfl;
wid=wgo/knid;
wfd2=wfd*wfd;
wwwg2=wwwg*wwwg;
wgo2=wgo*wgo;
wid2=wid*wid;
pahao=kpat-kfah*wfd2;
pfdo=pahao+z2*wfd2+z10*wfd+z12;
pfn=pfdo-z4*wfd2;
pecgo=pfn-kfg*wwwg2;
papgo=pecgo-kfapg*wgo2;
pido=papgo+z7*wid2+z11*wid+z13;
efd=k4fd*wfd2+k5fd*wfd*nfd+k6fd*nfd2;
eid=k4id*wid2+k5id*wid*nid+k6id*nid2;
end