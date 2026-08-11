% Initial conditions, Digital Model, Usoro, MIT, 1977
% "A drum boiler-turbine power plant under emergency
% state control", eqm 14jun'24 "const2.m"
%--------------------------------------------------------
% set control system input-output parameter values
k1mwd=-110.7e6; k2mwd=110.7e6; k1pss=81.37; k2pss=533.333;
k3pss=815.0; k4pss=2415.0; kpssol=0.0; kpssou=3015.0;
kcl=1.0; kcu=5.0; kavl=0.0; kavu=1.0; kwarl=0.0;
kwaru=1381.4; kwfll=0.0; kwflu=90.0; kpfnl=14.0; kpfnu=15;
%
kpfn=14.7; knp087=0.08727; ktrhol=1159.67; ktrhou=1559.67;
k1trh=1192.5; k2trh=0.4126; k3trh=1259.67; k4trh=1459.67;
ktrho=1459.67; kpfvdl=0.0; kpfvdu=40.0; kpfvd=30.0;
kxdrwl=-15; kxdrwu=15; kxdrw=0; kpdrsl=0; kpdrsu=4000.0;
%
kp1stl=0.0; kp1stu=2054.8; kwfwl=0.0; kwfwu=1250.0;
kxdewl=-20.0; kxdewu=20.0; kxdew=0.0; kprhol=0.0;
kprhou=800.0; kwcwl=0.0; kwcwu=1355.0; kwryl=0.0;
kwryu=50.0; kcryl=-2.0; kcryu=-1.0; k1tss=1338.0;
%
k2tss=0.1925; k3tss=1359.67; k4tss=1459.67; ktssol=1159.67;
ktssou=1559.67; ktsso=1459.67; kwsyl=0.0; kwsyu=100.0;
kcsyl=-5.0; kcsyu=-1.0; kmwtrl=0.0; kmwtru=531.36e6;
kmode=1.0; ksvreg=0.05; kcvreg=0.05; k1vreg=0.02;
kxggl=-0.5236; kxggu=0.5236; %%
% drum and deaerator water level
k1xdrw=-29.118; k2xdrw=0.02262; k3xdrw=1.9297e-6;
k1xdew=-29.138; k2xdew=-9.5377e-3; k3xdew=2.026e-6;
k1p1st=1.64384; kntrl=0.0; kntru=450.0; kntr=376.991;
kwgrl=0.0; kwgru=500.0; kwftl=0.0; kwftu=50.0; kcxgg=3.;
