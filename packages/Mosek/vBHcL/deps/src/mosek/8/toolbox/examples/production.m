%
%  Copyright : Copyright (c) MOSEK ApS, Denmark. All rights reserved.
%
%  File :      production.m
%
%  Purpose : Demonstrates how to modify and re-optimize a linear problem
%

function production()
clear prob;

% Specify the c vector.
prob.c  = [1.5 2.5 3.0]';

% Specify a in sparse format.
subi   = [1 1 1 2 2 2 3 3 3];
subj   = [1 2 3 1 2 3 1 2 3];
valij  = [2 4 3 3 2 3 2 3 2];

prob.a = sparse(subi,subj,valij);

% Specify lower bounds of the constraints.
prob.blc = [-inf -inf -inf]';

% Specify  upper bounds of the constraints.
prob.buc = [100000 50000 60000]';

% Specify lower bounds of the variables.
prob.blx = zeros(3,1);

% Specify upper bounds of the variables.
prob.bux = [inf inf inf]';

% Perform the optimization.
[r,res] = mosekopt('maximize',prob); 

% Show the optimal x solution.
res.sol.bas.xx

prob.a(1,1) = 3.0


prob.c       = [prob.c;1.0];
prob.a       = [prob.a,sparse([4.0 0. 1.0]')];
prob.blx     = zeros(4,1);
prob.bux     = [prob.bux; inf]


% select the primal simplex
param.MSK_IPAR_OPTIMIZER = 'MSK_OPTIMIZER_FREE_SIMPLEX'; 

[r,res] = mosekopt('minimize',prob,param) 




prob.a       = [prob.a;sparse([1.0 2.0 1.0 1.0])]; 
prob.blc     = [prob.blc;30000.0]; 
prob.buc     = [prob.buc;-inf]; 

