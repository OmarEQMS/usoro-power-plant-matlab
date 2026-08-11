function [waux,wh]=hpext(w)
% compute hp turbine steam extraction
w2=w*w;
w3=w2*w;
waux=17.15813+1.08e-2*w;
wh=-7.17593+0.09513*w-8.6643e-5*w2+6.187e-8*w3;
end