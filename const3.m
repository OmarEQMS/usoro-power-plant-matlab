% Initial conditions, Digital Model, Usoro, MIT, 1977
% "A drum boiler-turbine power plant under emergency
% state control", eqm 18jun'24 "const3.m"
%--------------------------------------------------------
% set control system gains and time constants
% valve and damper areas
adf=1.0; adi=1.0;
% boiler master demand
kc1md=20.0; kc2md=.5; ktc1md=60.0;
% air flow control
kc1ar=3; kc2arl=1.81656; kc4ar=1.; ktc1ar=60; ktc2ar=5.0;
% fuel flow control
kc1fl=3.0; kc3fl=1.; ktc1fl=60.0; ktc2fl=5.0;
% furnace pressure control
kc1fn=-1.25; kc2fn=0.0; kc3fn=1.; ktc1fn=40.0; ktc2fn=5;
% gas recirculation control
kc1gr=0.004; ktc1gr=20.0; kc2gr=12.0; kc3gr=1.0;
% boiler feedpump control
kc1ft=0.5; kc2ft=1.; ktc1ft=60.0; ktc2ft=5.;
% feedwater control
kc1fv=2.0; kc2fv=1.0; kc3fv=1.0; kc4fv=0.0; kc6fv=1.0;
ktc1fv=50.0; ktc2fv=120.0; ktc3fv=5.0;
% deaerator level control
kc1dv=10.0; kc2dv=1.0; kc4dv=0.1; kc5dv=.1; kc6dv=1.0;
ktc1dv=40.0; ktc2dv=2.; ktc3dv=120.0; ktc4dv=5.;
% reheat temperature control
kc1rh=5.0; kc2rh=-.01; kc3rh=.01; kc4rh=1.0; kc5rh=1.0;
ktc1rh=60.0; ktc2rh=5.; ktc3rh=5.; kc1ry=-1.0; kc1bt=1.0;
% superheat temperature control
kc1sy=10; kc2sy=.01; kc3sy=-.01; kc4sy=-1.; kc5sy=1;
ktc1sy=60.0; ktc2sy=5.0;
% turbine control
kc1ld=0.3; kc2ld=0.0; ktc1ld=1.0; kc1tr=1.0; kc2tr=1.0;
ktc1tr=10; ktc2tr=1; ktc3tr=1.0; ktc4tr=1.0; ktc5tr=1.0;
count=200.0; kmrl=0.5; kvrl=0.5; klrl=8.333e-3;

