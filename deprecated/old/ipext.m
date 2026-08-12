function [w2x,w3x,h2x,p2x,p3x]=ipext(w,p1,po,h1,ho)
% compute ip turbine steam extraction - flow and properties
po2=po*po;
po3=po2*po;
ht=h1+ho;
pt=p1+po;
w2=w*w;
w3=w2*w;
w2x=1.72456+2.72665e-2*w+2.7797e-5*w2;
w3x=-22.88702+0.17584*w-1.9372e-4*w2+1.0479e-7*w3;
p2x=0.449904*pt;
p3x=32.43505-0.4506405*po+6.851933e-3*po2-1.646941e-5*po3;
h2x=0.503488*ht;
end