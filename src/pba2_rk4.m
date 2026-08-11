% Prueba 2, Digital Model, Usoro47, MIT, 1977, pba2_rk4.m
% "A drum boiler-turbine power plant under emergency
% state control", orden=47
%--------------------------------------------------------
% Same Test-1 scenario as pba1_240814bk.m (load ramp 100%->77.5%
% at 15%/min, thesis V.1) but with ALL 47 states integrated:
% nfp (1) and ntr (16) are no longer hardcoded. The plant model
% is evaluated as a true f(t,x) in digpte47.m and advanced with
% classic fixed-step 4th-order Runge-Kutta at Ts=0.1 s, the same
% scheme the thesis used (DYSYS, p.49). RK4 is stable for the
% undamped ntr/delta swing pair; the previous frozen-derivative
% scheme (equivalent to explicit Euler) is not, which is why those
% states had to be frozen.
%--------------------------------------------------------
clear
close all
format short e
diginit100
const1
const2
const3
% Miscellanous initializations
t = -Ts;
%--------------------------------------------------------
%---------         >>>   MAIN LOOP   <<<           ------
%--------------------------------------------------------
for i=1:samples
  t = t + Ts;
  t0 = t - Ts;
  % classic RK4 step from t0 to t0+Ts
  [xd1,ylog]=digpte47(t0,x0);
  if(t>=tprint)
    xx2=[xx2;ylog];
    tprint=tprint+1; % graficas de resultados
  end
  xd2=digpte47(t0+Ts/2,x0+(Ts/2)*xd1);
  xd3=digpte47(t0+Ts/2,x0+(Ts/2)*xd2);
  xd4=digpte47(t0+Ts,x0+Ts*xd3);
  x0=x0+(Ts/6)*(xd1+2*xd2+2*xd3+xd4);
  xx=[xx;x0'];
end
% (1) p.65 ntr,mwo,psso,whp
ax1=subplot(221); plot(ax1,xx2(:,1),xx2(:,2));
ax2=subplot(222); plot(ax2,xx2(:,1),xx2(:,3));
ax3=subplot(223); plot(ax3,xx2(:,1),xx2(:,4));
ax4=subplot(224); plot(ax4,xx2(:,1),xx2(:,5));
title(ax1,'ntr'); title(ax2,'mwo');
title(ax3,'psso'); title(ax4,'whp');
res=[(1:47)' xx'];
figure % (2) p.66 cbmd,cacvd,c6fl,c6ar
ax1=subplot(221); plot(ax1,xx2(:,1),xx2(:,6));
ax2=subplot(222); plot(ax2,xx2(:,1),xx2(:,7));
ax3=subplot(223); plot(ax3,xx2(:,1),xx2(:,8));
ax4=subplot(224); plot(ax4,xx2(:,1),xx2(:,9));
title(ax1,'c3md'); title(ax2,'cacvd');
title(ax3,'cfld'); title(ax4,'card');
figure % (3) p.67 vdrw,vdew,c8fv,c9dv
ax1=subplot(221); plot(ax1,xx2(:,1),xx2(:,10));
ax2=subplot(222); plot(ax2,xx2(:,1),xx2(:,11));
ax3=subplot(223); plot(ax3,xx2(:,1),xx2(:,12));
ax4=subplot(224); plot(ax4,xx2(:,1),xx2(:,13));
title(ax1,'vdrw'); title(ax2,'vdew');
title(ax3,'cfwd'); title(ax4,'cdwd');
figure % (4) p.68 hsso,hrho,csyd,cxggd
ax1=subplot(221); plot(ax1,xx2(:,1),xx2(:,14));
ax2=subplot(222); plot(ax2,xx2(:,1),xx2(:,15));
ax3=subplot(223); plot(ax3,xx2(:,1),xx2(:,16));
ax4=subplot(224); plot(ax4,xx2(:,1),xx2(:,17));
title(ax1,'hsso'); title(ax2,'hrho');
title(ax3,'csyd'); title(ax4,'cxggd');
figure % (5) p.69 nfp,c2gr,c5fn,twwm
ax1=subplot(221); plot(ax1,xx2(:,1),xx2(:,18));
ax2=subplot(222); plot(ax2,xx2(:,1),xx2(:,19));
ax3=subplot(223); plot(ax3,xx2(:,1),xx2(:,20));
ax4=subplot(224); plot(ax4,xx2(:,1),xx2(:,21));
title(ax1,'nfp'); title(ax2,'cgrd');
title(ax3,'cfnd'); title(ax4,'twwm');
figure % (6) p.70 nfd,nid,nrp,ncp
ax1=subplot(221); plot(ax1,xx2(:,1),xx2(:,22));
ax2=subplot(222); plot(ax2,xx2(:,1),xx2(:,23));
ax3=subplot(223); plot(ax3,xx2(:,1),xx2(:,24));
ax4=subplot(224); plot(ax4,xx2(:,1),xx2(:,25));
title(ax1,'nfd'); title(ax2,'nid');
title(ax3,'nrp'); title(ax4,'ncp');
