%%
%  Copyright : Copyright (c) MOSEK ApS, Denmark. All rights reserved.
%
%  File :      eo1.m
%
%  Purpose :   An example on how to solve entropy optimization
%              problems using MOSEK Matlab Toolbox function mskenopt.
%%

function eo1()
d     = [1 1]'
c     = [-1 0]'
a     = [1 1]
blc   = 1
buc   = 1
[res] = mskenopt(d,c,a,blc,buc)
res.sol.itr.xx