%%
%
%  Copyright : Copyright (c) MOSEK ApS, Denmark. All rights reserved.
%
%  File :      nrm1.m
%
%  Purpose:   Solve the least-square problem
%
%             minimize || Fx - b||
%
%             reformulated as a QP
%
%             minimize 0.5 xF'Fx+0.5*b'*b-(F'*b)'*x
%%
function nrm1()
% Clear prob
clear prob;

F = [ [ 0.4302 , 0.3516 ]; [0.6246, 0.3384] ]
b = [ 0.6593, 0.9666]'

% Compute the fixed term in the objective.
prob.cfix = 0.5*b'*b

% Create the linear objective terms
prob.c = -F'*b;

% Create the quadratic terms. Please note that only the lower triangular
% part of f'*f is used.
[prob.qosubi,prob.qosubj,prob.qoval] = find(sparse(tril(F'*F)))

% Obtain the matrix dimensions.
[m,n]   = size(F);

% Specify a.
prob.a  = sparse(0,n);

[r,res] = mosekopt('minimize',prob);

% The optimality conditions are F'*(F x - b) = 0.
% Check if they are satisfied:

fprintf('\nnorm(f^T(fx-b)): %e\n',norm(F'*(F*res.sol.itr.xx-b)));