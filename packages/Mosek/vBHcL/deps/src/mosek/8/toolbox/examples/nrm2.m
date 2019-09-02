%
%  Copyright : Copyright (c) MOSEK ApS, Denmark. All rights reserved.
%
%  File :      nrm2.m
%
%  Purpose :   Continuation of nrm1.m.
%              Assume that the same objective should be
%              minimized subject to -1 <= x <= 1
%

function nrm2()

F = [ [ 0.4302 , 0.3516 ]; [0.6246, 0.3384] ]
b = [ 0.6593, 0.9666]'

% Compute the fixed term in the objective.
prob.cfix = 0.5*b'*b

% Create the linear objective terms
prob.c = -F'*b;

% Create the quadratic terms. Please note that only the lower triangular
% part of f'*f is used.
[prob.qosubi,prob.qosubj,prob.qoval] = find(sparse(tril(F'*F)));

% Obtain the matrix dimensions.
[m,n]   = size(F);

prob.blx = -ones(n,1);
prob.bux = ones(n,1);

% Specify a.
prob.a  = sparse(0,n);

[r,res] = mosekopt('minimize',prob);

% Check if the solution is feasible.
norm(res.sol.itr.xx,inf)