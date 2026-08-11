function [tfn1,twwge,twwgo,qwwgm,qpsr,swwgo]=fnxfer...
    (twwm,wwwg,war,sar,tapao,wfl,sfl,tfl,khfl,efl,wgr,...
    sgr,tgr,uwwgm,ywgr,tpse,upsr)
% compute furnace heat transfer
knp33=0.333333; kt0=537.0; k1sfn=0.31; k2sfn=0.145;
twwm2=twwm*twwm;
twwm4=twwm2*twwm2;
tpse2=tpse*tpse;
tpse4=tpse2*tpse2;
sfn=k1sfn+k2sfn*ywgr;
tfn1=kt0+(wfl*khfl*efl+wfl*sfl*(tfl-kt0)+war*sar*...
    (tapao-kt0)+wgr*sgr*(tgr-kt0))/(wwwg*sfn);
z1=uwwgm+upsr;
z2=2*wwwg*sfn;
z3=uwwgm*twwm4+upsr*tpse4+z2*tfn1;
z4=z2/z1;
z5=z3/z1;
z6=0.5*z4*z4;
z7=4*z5/3;
z8=sqrt(z7*z7*z7+z6*z6);
z9=(z6+z8)^knp33;
z10=(z8-z6)^knp33;
z11=z9-z10;
z12=sqrt(z11*z11+4*z5);
twwge=0.5*(sqrt(2*z12-z11)-sqrt(z11));
twwgo=2*twwge-tfn1;
twwge2=twwge*twwge;
twwge4=twwge2*twwge2;
qwwgm=uwwgm*(twwge4-twwm4);
qpsr=upsr*(twwge4-tpse4);
swwgo=sfn;
end