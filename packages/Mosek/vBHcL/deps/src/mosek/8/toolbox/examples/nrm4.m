%%
%  Copyright : Copyright (c) MOSEK ApS, Denmark. All rights reserved.
%
%  File :      nrm4.m
%
%  Purpose :  Solve a linear least-squares problem using the
%             || ||_1 norm
%
%             minimize || Fx - b ||_1
%
%             is reformulated as 
%
%             minimize e^T t
%
%                      F x - b   <= t
%                   -( F x - b ) <= t
%%


function nrm4()
clear prob;

F = [ [ 0.4302 , 0.3516 ]; [0.6246, 0.3384] ]
b = [ 0.6593, 0.9666]'

% Obtain the matrix dimensions.
[m,n]   = size(F);

prob.c   = [sparse(n,1)   ; ones(m,1)];
prob.a   = [[F,-speye(m)] ; [F,speye(m)]];
prob.blc = [-inf*ones(m,1); b];
prob.buc = [b             ; inf*ones(m,1)];

[r,res]  = mosekopt('minimize',prob);

% The optimal objective value is given by:
norm(F*res.sol.itr.xx(1:n)-b,1) 