function [r,T,s]=systat(h,p)
% compute superheat spray section outlet steam properties
ph=p*h;
r=-1.9033+1.3862e-3*h+6.7569e-3*p-3.7659e-6*ph;
T=-1654.5+1.7443*h+0.34809*p-2.0743e-4*ph+459.67;
s=0.46472+7.9581e-4*h-1.1683e-5*p-1.8658e-8*ph;
end