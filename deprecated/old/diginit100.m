% Initial conditions, Digital Model, Usoro, MIT, 1977
% "A drum boiler-turbine power plant under emergency
% state control", eqm 13jun'24 "diginit100.m"
%-----------------------------------------------------------
% constants
% set constant values
knp33=0.333333; knp5=0.5; knp6=0.6; knp79=0.788654; 
knp8=0.8; kn1p3=1.234; kn0=0.0; kn1=1.0; km1=-1.0; 
kn2=2.0; kn3=3.0; kn4=4.0; km4=-4.0; kn5=5.0; km5=-5.0;
kn6=6.0; kn144=144.0; kmwx=1.355e-6; kmwr=4.428e8;
kntr=377.0; kc1gn=1.0;
% set system parameter values from subroutines const1,const2,const3
% const1
% const2
% const3
ldc=5.0; kmrl=0.111; catvd=5.0; caivd=5.0;
% initialize variables for computing their time derivatives 100%
c2dv0=0.0; cp1st0=4.5464; ctrho0=3.6667; cxgg0=3.0;
c2dv=0.0; cp1st=4.5464; ctrho=3.6667; cxgg=3.0;
% initialize variables for computing their time derivatives 77.5%
% c2dv0,cp1st0,ctrho0,cxgg0  c2dv,cp1st,ctrho,cxgg
% c2dv0=1.3898e-04; cp1st0=3.4628e+00; ctrho0=4.0015e+00; cxgg0=2.9860e+00;
% c2dv=1.3869e-04; cp1st=3.4628e+00; ctrho=4.0015e+00; cxgg=2.9860e+00;
% initialize jcount, udes in selecting printing interval
jcount=0;
% compute load reference motor, valve, and load rate limits
% compute time derivatives
tstep=0.4;
fc2dv=(c2dv-c2dv0)/tstep;
fcp1st=(cp1st-cp1st0)/tstep;
fctrho=(ctrho-ctrho0)/tstep;
fcxgg=(cxgg-cxgg0)/tstep;
c2dv0=c2dv; %
cp1st0=cp1st;
ctrho0=ctrho;
cxgg0=cxgg;
% Initial states 100%, ldc=5, pág.288 usoro 
x0=[542.15; 478.11; 634.72; 1170.5; 9.4534;...   %1-5
    187.19; 1159.8; 5.0129; 1247.9; 3.1381;...   %6-10
    1460.1; 2.5600; 0.65599; 1519.0; 0.25448;... %11-15
    376.99; 186.56; 198.99; 6817.4; 0.13307;...  %16-20
    61.880; 92.452; 4.5628; 4.5500; 4.5622;...   %21-25
    4.9586; 2.4688; 4.0743; 4.9667e-3; 4.6042;...%26-30
    5.8393e-3; 4.5196; 3.1173; 4.4259; 4.5486;...%31-35
    4.5617; 4.9573; 2.4688; 4.0737; 4.6034;...   %36-40
    4.5238; 3.1167; 4.4245; 0.0; 5.0; 5.00; 0.52362]; %47
% Initial states 77.5%, ldc=3.875
% Initial states 50%, ldc=2.5
xx=x0';xx2=[]; x00=x0; tprint=0;
% equivalence
nfp=x0(1); hhho=x0(2); heco=x0(3); vdrw=x0(4); 
rdrs=x0(5); nrp=x0(6); twwm=x0(7); rpso=x0(8); 
hpso=x0(9); rsso=x0(10); hsso=x0(11); rsco=x0(12);
rrho=x0(13); hrho=x0(14); rcro=x0(15); ntr=x0(16); 
ncp=x0(17); hlho=x0(18); vdew=x0(19); rdes=x0(20); 
nfd=x0(21); nid=x0(22); c3md=x0(23); % 23 ss
c5ar=x0(24); c5fl=x0(25); c3fn=x0(26); c2gr=x0(27);
c2ft=x0(28); c3fv=x0(29); c7fv=x0(30); c3dv=x0(31);
c8dv=x0(32); c5rh=x0(33); c5sy=x0(34); card=x0(35);
cfld=x0(36); cfnd=x0(37); cgrd=x0(38); cftd=x0(39);
cfwd=x0(40); cdwd=x0(41); cxggd=x0(42); csyd=x0(43);
c2tr=x0(44); c4tr=x0(45); cacvd=x0(46); delta=x0(47);
% --  System to be Controlled (MATLAB)  --
mat_model = 'digpte';       % Name of MATLAB model
%model_out = 'stdout'; % Output equation (function of the states)
% ------    General Initializations  -------
Ts = 0.1;           % Sampling period (in seconds)
%samples  = 7001;    % Number of samples to be simulated
samples  = 7001;