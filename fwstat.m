function [r,T]=fwstat(h,p)
% compute feedwater properties
p2=p*p;
h2=h*h;
hp=h*p;
h2p2=h2*p2;
r=71.143-5.0804e-3*p-3.2658e-2*h+1.1688e-5*hp+6.1657e-7*p2...
    -3.0631e-5*h2-2.3095e-12*h2p2;
T=146.98-0.088486*p+0.79716*h+1.8034e-4*hp+1.0481e-5*p2...
    -1.8231e-4*h2-3.812e-11*h2p2+459.67;
end