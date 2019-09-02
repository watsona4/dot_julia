function [ret] = mskgpspa(nlh,yo,yc)
% Purpose: Is used by mskgpopt to compute the sparsity pattern 
%          of the nonlinear functions.
%
%% Copyright (c) MOSEK ApS, Denmark. All rights reserved. 

m = nlh.m;
t = nlh.t;

if yo~=0  
  ret.hes = tril(nlh.hesout*nlh.hesout')...
            + sparse(nlh.subt,nlh.subt,ones(size(nlh.subt)),t,t);  
else 
  ret.hes = sparse(t,t);
end

ret.rcode = 0;

% nnz(ret.hes)