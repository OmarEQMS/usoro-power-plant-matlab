function [wderp,wdewh,wdebd,hderp,hdewh]=destmr(wdrs,whp)
% compute deaerator heating steam -flow and properties
whp2=whp*whp;
wdrs2=wdrs*wdrs;
wdrs3=wdrs2*wdrs;
wderp=15.0975;
wdewh=8.45534+2.8201e-3*whp-8.58e-7*whp2;
wdebd=0.16331+7.319e-4*wdrs+4.462e-6*wdrs2-2.51e-9*wdrs3;
hderp=295.60;
hdewh=179.01095+9.66338e-2*whp-3.55714e-5*whp2;
end