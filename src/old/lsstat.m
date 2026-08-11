function [h,r,T]=lsstat(p)
% compute feedwater heating steam properties
p2=p*p;
p3=p2*p;
h=126.8737+4.15377*p-0.04224*p2+1.8e-4*p3;
r=60.53211-0.04603*p;
T=159.09642+4.1294*p-0.04236*p2+1.8e-4*p3+459.67;
end