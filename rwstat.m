function [h,T,s]=rwstat(r,p)
% compute recirculating water properties
rp=r*p;
r2=r*r;
p2=p*p;
T=163.60+29.199*r+4.2676e-2*p-7.2625e-4*rp-.45712*r2...
    +3.1826e-7*p2;
h=658.45+11.887*r+3.9498e-2*p-5.6695e-4*rp-.31712*r2...
    -3.2973e-7*p2;
s=.7395+1.7257e-2*r+2.8021e-5*p-4.7572e-7*rp...
    -3.7372e-4*r2+2.4354e-10*p2;
end