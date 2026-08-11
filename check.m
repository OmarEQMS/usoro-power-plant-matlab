function zc=check(zc,zmax,zmin)
% check that variable (zc) is within limits (zmin-zmax)
if(zc<zmin); zc=zmin; end
if(zc>zmax); zc=zmax; end
end
