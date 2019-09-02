%
%  Copyright : Copyright (c) MOSEK ApS, Denmark. All rights reserved.
%
%  File :      nrm3.m
%
%  Purpose :  Solve a linear least-squares problem using the
%             || ||_inf norm
%
%             minimize || Fx - b ||_inf
%
%             is reformulated as 
%
%             minimize \tau 
%
%                      Fx + \tau e - b >= 0
%                      Fx - \tau e - b <= 0
%

function nrm3()
clear prob;


F = [ [ 0.4302 , 0.3516 ]; [0.6246, 0.3384] ]
b = [ 0.6593, 0.9666]'


% Obtain the matrix dimensions.
[m,n]   = size(F);

prob.c   = sparse(n+1,1,1.0,n+1,1);
prob.a   = [[F,ones(m,1)];[F,-ones(m,1)]];
prob.blc = [b            ; -inf*ones(m,1)];
prob.buc = [inf*ones(m,1); b             ];

[r,res]  = mosekopt('minimize',prob);

% The optimal objective value is given by:
norm(F*res.sol.itr.xx(1:n)-b,inf) 