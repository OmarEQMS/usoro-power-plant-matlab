function [w1lhs,w2lhs,wdex,wlhst,p1lhs,p2lhs,p3lhs,...
    h1lhs1,h2lhs1,hdex]=lpext(wlp,pcro,pcn,hcro,hlpo)
% compute lp turbine steam extraction - flow and properties
wlp2=wlp*wlp;
wlp3=wlp2*wlp;
plpt=pcro+pcn;
hlpt=hcro+hlpo;
w1lhs=-1.04759+9.97993e-2*wlp-6.8253e-5*wlp2+6.14e-8*wlp3;
w2lhs=-6.73762+8.48847e-2*wlp-1.3439e-5*wlp2;
wdex=4.9696+1.75669e-2*wlp+3.0622e-5*wlp2;
wlhst=w1lhs+w2lhs;
p1lhs=0.13571*plpt;
p2lhs=0.029372*plpt;
p3lhs=0.63009-7.0492e-2*p1lhs+6.3411e-3*p1lhs*p1lhs...
    -1.298e-4*p1lhs*p1lhs*p1lhs;
h1lhs1=0.498953*hlpt;
h2lhs1=0.458364*hlpt;
hdex=0.533921*hlpt;
end