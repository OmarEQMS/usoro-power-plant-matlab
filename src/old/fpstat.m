function [h,T]=fpstat(r,p)
% compute feedpump exhaust water properties
r2=r*r;
p2=p*p;
pr=p*r;
h=9024.90+0.11479*p-90.346*r-2.0528e5/r-1.8098e-3*pr;
T=-1268.8+82.714*r+0.10301*p-1.4744e-3*pr-0.97073*r2-...
    1.801e-6*p2+459.67;
end