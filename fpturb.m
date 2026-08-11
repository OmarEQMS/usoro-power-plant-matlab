function [tqfp1,mwfp1]=fpturb(wft,hft1,nfp)
% compute feedpump turbine torque
kj=778.17;
hfto=1059.0;
eft=1.0;
mwfp1=wft*(hft1-hfto)*eft*kj;
tqfp1=mwfp1/nfp;
end