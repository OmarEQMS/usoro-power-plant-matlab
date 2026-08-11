function [hlpo,rlpo,slpo,T,rw,hw]=cnstat(p,qy)
% compute condenser water and steam, and LP turbine exhaust
% steam properties
p2=p*p;
p3=p2*p;
p4=p3*p;
p5=p4*p;
rw=62.34525-0.28884*p;
rs=2.0e-5+3.21e-3*p-3.2e-4*p2+8.0e-5*p3;
hw=-25.80341+365.63647*p-878.10799*p2+1305.19564*p3-...
    1002.14134*p4+305.01148*p5;
hs=1075.86634+28.99664*p;
T=6.2916+364.60878*p-877.92172*p2+1311.45665*p3-...
    1012.17821*p4+309.49426*p5+459.67;
sw=-0.05216+0.74502*p-1.84119*p2+2.75801*p3-2.12467*p4+...
    0.64777*p5;
ss=2.21936-0.58673*p+0.51817*p2-0.16668*p3;
hlpo=hw+qy*(hs-hw);
rlpo=rw+qy*(rs-rw);
slpo=sw+qy*(ss-sw);
end
