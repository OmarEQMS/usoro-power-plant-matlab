function [w]=shflow(r,pd,kf)
% compute superheater steam flow
kd1=1;
if(pd<0) 
    pd=-pd;
    kd1=-1;
end
zw=sqrt(pd*r/kf);
w=zw*kd1;
end
