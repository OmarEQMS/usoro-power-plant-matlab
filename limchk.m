function zc=limchk(zc)
% check that control variable (zc) is within limits (1-5)
if(zc<1); zc=1; end
if(zc>5); zc=5; end
end

