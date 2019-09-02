%%
%  Copyright : Copyright (c) MOSEK ApS, Denmark. All rights reserved.
%
%  File :      mioinitsol.m
%
%   Purpose:   To demonstrate how to solve a MIP with a start
%   guess.
%%

function mioinitsol()
[r,res]       = mosekopt('symbcon');
sc            = res.symbcon;

clear prob

prob.c        = [7 10 1 5];
prob.a        = sparse([1 1 1 1 ]);
prob.blc      = -[inf];
prob.buc      = [2.5];
prob.blx      = [0 0 0 0];
prob.bux      = [inf inf inf inf];
prob.ints.sub = [1 2 3];

% Values for the integer variables are specified.
prob.sol.int.xx  = [0 2 0 0]';

% Tell Mosek to construct a feasible solution from a given integer
% value. 
param.MSK_IPAR_MIO_CONSTRUCT_SOL = sc.MSK_ON;

[r,res] = mosekopt('maximize',prob,param);

try
  % Display the optimal solution.
  res.sol.int.xx'
catch
  fprintf('MSKERROR: Could not get solution')
end