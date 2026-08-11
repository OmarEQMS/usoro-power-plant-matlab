function c=xducer(zmin,zmax,cmin,cmax,z)
% input-output conversion. 
% physical variable to control signal and vise versa
c=cmin+(cmax-cmin)*(z-zmin)/(zmax-zmin);
if(c<cmin); c=cmin; end
if(c>cmax); c=cmax; end
end

