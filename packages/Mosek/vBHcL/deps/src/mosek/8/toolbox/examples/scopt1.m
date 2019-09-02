%%
%  Copyright : Copyright (c) MOSEK ApS, Denmark. All rights reserved.
%
%  File :      scopt1.m
%
%  Purpose :   Demonstrates how to solve a simple non-liner separable problem
%              using the MATLAB toolbox. Then problem is this:
%
%              Minimize   e^x2 - ln(x1)
%              Such that  x2 ln(x2)   <= 0
%                         x1^1/2 - x2 >= 0
%                          1/2 <= x1, x2     <= 1
%
%%

function scopt1()
% Specify the linear part of the problem.

c           = [0;0];
a           = sparse([[0 0];[0 -1 ]]);
blc         = [-inf;    0];
buc         = [   0;  inf];
blx         = [ 0.5;  0.5];
bux         = [ 1.0;  1.0];

opr  = ['log'; 'exp'; 'ent'; 'pow'];
opri = [0    ;     0;     1;     2];
oprj = [1    ;     2;     2;     1];
oprf = [-1   ;     1;     1;     1];
oprg = [1    ;     1;     0;   0.5];
oprh = [0    ;     0;     0;     0];


% Call the optimizer.
% Note that bux is an optional parameter which should be added if the variables
% have an upper bound. 

[res]       = mskscopt(opr,opri,oprj,oprf,oprg,c,a,blc,buc,blx,bux); 
                                                                 

% Print the solution.
res.sol.itr.xx