function [p,T,s]=rhstat(r,h)
% compute reheat steam properties
rh=r*h;
p=27.061-1019.1*r-1.7354e-2*h+1.2279*rh;
T=-2013.4+189.65*r+1.9629*h-9.3054e-2*rh+459.67;
s=1.5015+3.8306e-3*r+6.4181e-4*h-0.10938*log(rh);
end

