function [tgo,q,tme,sgo]=hxfer...
    (wg,ws,kugm,kums,tse,tg1,qr,ywgr)
% compute gas-path heat transfer
k0sg=0.2484; k1sg=0.1428; ksgt=10.2272e-6; ksgw=35.0e-6;
ws=abs(ws);
ugm=kugm*wg^0.6;
ums=kums*ws^0.8;
ugs=ugm*ums/(ugm+ums);
z1=k0sg+k1sg*ywgr;
z2=ksgt+ksgw*ywgr;
z3=0.5*ugs;
z4=wg*z1;
z5=wg*z2;
z6=z3+z4;
z7=z3*tg1-ugs*tse-z5*tg1*tg1-z4*tg1;
tgo=0.5*(sqrt(z6*z6-4*z5*z7)-z6)/z5;
% SG=Z1+Z2*(TG1+TGO) in the printed listing (PAT11075): mean of the
% linear-in-T gas specific heat s(T)=z1+2*z2*T over inlet/outlet, matching
% the tgo quadratic above. A '-' here was a transcription slip (fixed with
% the OOP model, Aug 2026).
sg=z1+z2*(tg1+tgo);
qc=wg*sg*(tg1-tgo);
q=qc+qr;
tme=tse+qc/ums;
sgo=z1+z2*2*tgo;
end