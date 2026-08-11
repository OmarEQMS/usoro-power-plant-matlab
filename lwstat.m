function [h,r,T]=lwstat(p)
% compute feedwater heating steam (water?) properties
p2=p*p;
p3=p2*p;
h=32.5+43.49757*p-7.38007*p2+0.51472*p3;
r=62.34525-0.28884*p;
T=64.05911+43.60199*p-7.40196*p2+0.51616*p3+459.67;
end