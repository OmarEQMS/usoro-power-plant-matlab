function [wfp,wfw,wfw2,pbpo,pfpo,pfvo,phho,pfvd,efp]=fwflow...
    (wry,wsy,rdew,pdes,pdrs,reco,afv,nfp)
% compute feedwater flow
k1fp=-57.3012e-3; k2fp=959.4371e-6; k3fp=203.8473e-6;
k4fp=-1.735761e-3; k5fp=129.1779e-6; k6fp=548.9264e-9;
k1bp=-2.63447e-3; k2bp=200.721e-6; k3bp=99.9049e-6;
kfhh=4.7469e-3; kfec=3.878121e-3; kfv=1.1721e-3;
kwfpx=19.6677; knbpr=0.333333;
knbpr2=knbpr*knbpr; %
nbp=knbpr*nfp;
nbp2=nbp*nbp;
nfp2=nfp*nfp;
afv2=afv*afv;
z1=kwfpx+wry+wsy;
z2=kfv/(afv2*rdew);
z3=kfhh/rdew;
z4=kfec/reco;
z5=k1fp/rdew;
z6=k1bp/rdew;
z7=k2fp*nfp;
z8=k2bp*nbp;
z9=k3fp*nfp2*rdew;
z10=k3bp*nbp2*rdew;
z11=z2+z3+z4;
z12=z5+z6;
z13=z7+z8;
z14=z9+z10+pdes-pdrs;
z15=z11-z12;
z16=2*z11*z1+z13;
z17=z14-z11*z1*z1;
wfp=0.5*(sqrt(z16*z16+4*z15*z17)+z16)/z15;
wfw=wfp-z1;
wfp2=wfp*wfp;
wfw2=wfw*wfw;
pbpo=pdes+z6*wfp2+z8*wfp+z10;
pfpo=pbpo+z5*wfp2+z7*wfp+z9;
pfvo=pfpo-z2*wfw2;
phho=pfvo-z3*wfw2;
pfvd=pfpo-pfvo;
efp=k4fp*wfp2/(rdew*rdew)+k5fp*wfp*nfp/rdew+k6fp*nfp2;
end
