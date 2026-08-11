function [x1m,x2m,x3m]=averag(x11,x12,x21,x22,x31,x32)
% compute average values
x1m=0.5*(x11+x12);
x2m=0.5*(x21+x22);
x3m=0.5*(x31+x32);
end