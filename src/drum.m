function [f1dr,f2dr]=drum(kvdr,vdrw,rdrs,rdrw,hdrw,hdrs,...
    k2,k3,k5,k6,k7,k9,k10,z206,z209)
% compute drum variables
vdrs=kvdr-vdrw;
z200=2*rdrs;
z201=k2+k3*z200;
z202=k5+k6*z200+3*k7*rdrs*rdrs;
z203=k9+k10*z200;
z204=rdrw-rdrs;
z205=vdrs+vdrw*z201;
z207=rdrw*hdrw-rdrs*hdrs;
z208=vdrs*hdrs+vdrw*hdrw*z201+vdrw*rdrw*z202+vdrs*rdrs*z203;
z210=z204*z208-z205*z207;
f1dr=(z206*z208-z205*z209)/z210;
f2dr=(z204*z209-z206*z207)/z210;
end