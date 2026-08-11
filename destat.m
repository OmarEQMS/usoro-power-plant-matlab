function [rw,hw,hs,ps,ts]=destat(rs)
% compute deareator water and steam properties
rs2=rs*rs;
rs3=rs2*rs;
rw=60.45805-19.61207*rs;
hw=118.26296+1905.63721*rs-8414.69018*rs2+15688.03769*rs3;
hs=1143.4984+224.556*rs;
ps=-1.04181+419.17159*rs+131.32803*rs2;
ts=150.48933+1896.4155*rs-8447.87828*rs2+15757.43239*rs3+459.67;
end