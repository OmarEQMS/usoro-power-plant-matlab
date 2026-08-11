function [tq1,mw1]=torque(nelec,velec,knm,n,km,smax)
% compute induction motor torque
nmax=nelec/knm;
s=(nmax-n)/nmax;
velec2=velec*velec;
tq1=km*velec2/(s/smax+smax/s);
mw1=tq1*n;
end