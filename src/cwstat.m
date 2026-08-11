function [r,T]=cwstat(h,p)
% compute condensate (water) properties
p2=p*p;
h2=h*h;
hp=h*p;
r=62.633+2.3086e-4*p-7.847e-3*h+8.4526e-7*hp-...
    1.3075e-7*p2-4.4171e-5*h2;
T=31.363-3.6799e-3*p+1.0224*h+2.2581e-6*hp+1.3108e-6*p2-...
    9.8358e-5*h2+459.67;
end