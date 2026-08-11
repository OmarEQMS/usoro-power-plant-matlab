% Initial conditions, Digital Model, Usoro, MIT, 1977
% "A drum boiler-turbine power plant under emergency
% state control", eqm 13jun'24 "const1.m"
%--------------------------------------------------------
% set system parameters values
% heat transfer coefficients
kuwwgm=3.187029e-9; kuwwmw=173.5205; kupsr=138.576e-12;
kupsgm=1.80123; kupsms=2.34465; kussgm=3.75513;
kussms=6.753101; kurhgm=8.0954; kurhms=4.47939; 
kuecgm=9.32379; kuecmw=8.591464;
% metal masses
kmwwm=1063000.0; kmpsm=350000.0; kmssm=800000.0;
kmrhm=944000.0; kmecm=721000.0; kmlhm=70376.0;
kmhhm=108400.0;
% specific heat of metal
kswwm=0.11; kspsm=0.11; ksssm=0.11; ksrhm=0.11;
ksecm=0.11; kslhm=0.11; kshhm=0.11;
% fill volumes
% kvec,kvrh,kvcre,kvss,kvps reset to newly computed values
kvww=2318.61; kvps=2000.0; kvss=3000; kvrh=6000.0;
kvec=2100.0; kvlh=93.02; kvhh=114.67; kvdr=1958.72;
kvde=8029.9; kvsce=700.0; kvcre=1220.0;
% feedwater heaters metal temperature - constants
klhm=1.05; khhm=1.05;
% drum and deaerator constants
k2=-2.13733; k3=0.03348; k5=31.0437; k6=-0.62086; k7=0.0;
k9=-21.3442; k10=0.20998; k22=-19.61207; k23=0.0;
k25=1905.6372; k26=-8414.69018; k27=15688.03769;
k29=224.556; k30=0.0;
% drive motor constants
nelec=376.991; velec=4160.0; knrpm=2.0; krpm=476.146e-6;
srpmax=0.05; kncpm=2.0; kcpm=615.533e-6; scpmax=0.05;
knfdm=6.0; kfdm=4.1e-3; sfdmax=0.05; knidm=4.0;
kidm=6.16e-3; sidmax=0.05;
% rotor inertia;
kjtre=625000.0; kjfpe=2161.7; kjrp=576.1; kjcp=468.0;
kjfd=181900.0; kjid=188000.0;
% miscellaneous
kwtv=506.7; khp=15.6; kip=51.78706; klp=126.41;
ktv=32.0; kcv=12.74214; kfv=482.3549e-6; k0pcn=0.26449;
k1pcn=1.38076e-4; k2pcn=1.30065e-5; kqylpo=0.92632;
kj=778.17; ketr=0.955; kwfw=493.03; kqgc=1647.52;
kpat=14.7; ktat=510.0; ktahad=88.0; ktapad=350.0;
k1tgr=929.69; k2tgr=2.15172; sar=0.252; sfl=0.490;
tfl=650.0; khfl=18200.0; efl=1.0; sgr=0.27; ywgr=0.0;
kr=0.357639; kafr=13.6507;
% friction coefficients
kfdc=719.028e-6; kfww=159.751e-6; kfps=1.88e-3; 
kfss=3.162e-4; kfrh=45.90723e-6; kflh=3.914168e-3;
kfhh=5.711565e-3; kfec=3.878121e-3;
% number of operating pumps and fans
knrp=6.0; kncp=2.0;
knfd=2.0; knid=2.0; 
% burner tilt and number of operating guns
k1xgg=1.0; k2xgg=-0.286483; ng1=4.0; ng2=4.0; ng3=4.0;
ng4=4.0; ng5=4.0; k1ng=79.868; k2ng=72.201; k3ng=64.534;
k4ng=56.867; k5ng=49.200; kxwwe=64.534;
