function [ret] = mskenspa(nlhand,yo,yc)
% Purpose: Is used by entopt to compute the sparsity pattern 
%          of the nonlinear functions.
%
%% Copyright (c) MOSEK ApS, Denmark. All rights reserved.

n = nlhand.n;

if yo~=0  
  ret.hes = sparse(nlhand.grdobjsub,nlhand.grdobjsub,ones(nlhand.nzgo,1),n,n); 
else 
  ret.hes = sparse(n,n);
end

ret.rcode = 0;
