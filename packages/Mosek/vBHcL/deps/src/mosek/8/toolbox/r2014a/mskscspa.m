function [ret] = mskscspa(nlhand,yo,yc)
% Purpose: Is used by mskscopt to compute the sparsity pattern 
%          of the nonlinear functions.
%
%% Copyright (c) MOSEK ApS, Denmark. All rights reserved.

numvar    = nlhand.numvar;

yc        = yc(:);
y         = [yo;yc];

ret.hes   = sparse(nlhand.oprj,nlhand.oprj,y(1+nlhand.opri),numvar,numvar); 
ret.rcode = 0;
