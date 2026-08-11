function [wrw,wrp,wwwo,pdco,prpo,erp]=rwflow...
    (knrp,rdc,rdrw,nrp,pdrs)
% compute recirculating water flow
kn144=144.0; kldc=137.0; kwrps=4.3014; k1rp=-1.73366e-3;
k2rp=1.64728e-4; k3rp=5.5798e-5; k4rp=-1.3391e-3;
k5rp=3.45853e-4; k6rp=2.8937e-6; kfdc=381.048e-6;
kfww=84.6537e-6; 
nrp2=nrp*nrp;
knrp2=knrp*knrp;
z1=kfdc/rdc;
z2=kldc*rdc/kn144;
z3=k1rp/rdc;
z4=k2rp*nrp;
z5=k3rp*nrp2*rdc;
z6=kfww/rdrw;
z7=kldc*rdrw/kn144;
z8=z1-z3+z6*knrp2;
z9=z4-2*z6*knrp*kwrps;
z10=z5+z2-z7-z6*kwrps*kwrps;
wrp=0.5*(sqrt(z9*z9+4*z8*z10)+z9)/z8;
wrw=knrp*wrp;
wwwo=wrw+kwrps;
wrp2=wrp*wrp;
pdco=pdrs-z1*wrp2+z2;
prpo=pdco+z3*wrp2+z4*wrp+z5;
erp=k4rp*wrp2/(rdc*rdc)+k5rp*wrp*nrp/rdc+k6rp*nrp2;
end
