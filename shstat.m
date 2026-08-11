function [p,T,s]=shstat(r,h)
% compute superheater steam properties
rh=r*h;
p=-291.36-964.04*r+0.21781*h+1.1815*rh;
T=-1745.1+129.1*r+1.8107*h-0.066313*rh+459.67;
s=1.3136-1.7799e-3*r+6.3573e-4*h-8.3591e-2*log(rh);
end