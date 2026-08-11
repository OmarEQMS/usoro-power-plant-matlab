function [ho,T]=hpstat(s,p,ef,h1)
% compute hp turbine exhaust steam properties
hi=-485.23+1065.28*s+0.232*p;
ho=h1-ef*(h1-hi);
T=-1639.24+0.119*p+1.682*ho;
end

