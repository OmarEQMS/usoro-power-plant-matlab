function [ho,p,T]=crstat(s,r,ef,h1)
% compute cross-over pipe steam properties
hi=-1211.8+683.58*r+1384.39*s;
ho=hi-ef*(h1-hi);
p=-381.05+0.2783*ho+668.609*r;
T=-2074.92+2.004*ho+71.326*r+459.7;
end