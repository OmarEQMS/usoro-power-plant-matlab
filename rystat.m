function [r,T,s]=rystat(h,p)
% compute reheat spray section outlet steam properties
p2=p*p;
h2=h*h;
p2h2=p2*h2;
ph=p*h;
r=-4.2661e-2+3.0892e-5*h+6.2923e-3*p-3.4891e-6*ph;
T=-550.34-0.39473*h+1.6795*p-1.1363e-3*ph+9.3611e-4*h2...
    -4.1249e-4*p2+2.0849e-10*p2h2+459.67;
s=-0.473+2.47e-3*h-2.7302e-4*p-3.1543e-7*ph-5.6242e-7*h2+...
    2.8235e-7*p2+8.9539e-14*p2h2;
end