function [rw,hw,hs,ps,Ts]=drstat(rs)
% compute drum water and steam properties
% kdr1=49.271; kdr2=-2.137; kdr3=0.03348; kdr4=1241.7; kdr5=-21.344;
% kdr6=0.21; kdr7=526.6; kdr8=31.044; kdr9=-0.6209;
rs2=rs*rs;
rs3=rs2*rs;
rw=49.27105-2.13733*rs+0.03348*rs2;
hw=526.5957+31.0437*rs-0.62086*rs2;
hs=1241.713-21.3442*rs+0.20998*rs2;
ps=11.1877+500.267*rs-26.4031*rs2+0.46944*rs3;
Ts=458.084+48.2088*rs-3.2326*rs2+0.07249*rs3+459.67;
% ps=459.41+358.61*rs-12.04*rs2;
% Ts=616.75+6.691*rs+459.67;
end