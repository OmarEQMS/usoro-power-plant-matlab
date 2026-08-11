function [wcw,wcp,pcpo,plho,wlhx,wdvo,ecp]=cwflow...
    (pcn,rcno,rdvo,pdes,ncp,adv,kncp)
% compute condensate (water) flow
kflh=3.914168e-3; kdv=9.434e-3; k1cp=-1.64515e-2;
k2cp=1.20115e-4; k3cp=1.57933e-4; k4cp=-8.88465e-3;
k5cp=9.2870e-4; k6cp=4.34174e-7; k1lhx=25.60544;
k2lhx=7.32295e-2; k3lhx=-1.6317e-5; 
adv2=adv*adv;
ncp2=ncp*ncp;
kncp2=kncp*kncp;
z1=k1cp/rcno;
z2=k2cp*ncp;
z3=k3cp*ncp2*rcno;
z4=kflh*kncp2/rcno;
z5=kdv*kncp2/(adv2*rdvo);
z6=z4+z5-z1;
z7=z3+pcn-pdes;
wcp=0.5*(sqrt(z2*z2+4*z6*z7)+z2)/z6;
wcw=kncp*wcp;
wcp2=wcp*wcp;
wcw2=wcw*wcw;
wlhx=k1lhx+k2lhx*wcw+k3lhx*wcw2;
wdvo=wcw-wlhx;
pcpo=pcn+z1*wcp2+z2*wcp+z3;
plho=pcpo-z4*wcp2;
ecp=k4cp*wcp2/(rcno*rcno)+k5cp*wcp*ncp/rcno+k6cp*ncp2;
end