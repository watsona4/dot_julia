%%
%    Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.
%
%    File:    mioinitsol.m
%
%    Purpose:  Demonstrates how to solve a small mixed
%              integer linear optimization problem
%              providing an initial feasible solution.
%%

function mioinitsol()

import mosek.fusion.*;

c = [  7.0, 10.0, 1.0, 5.0];

M = Model('mioinitsol');
  
n = 4;

x = M.variable('x', n, Domain.integral(Domain.greaterThan(0.0)));

M.constraint( Expr.sum(x), Domain.lessThan(2.5));

M.setSolverParam('mioMaxTime', 60.0);
M.setSolverParam('mioTolRelGap', 1e-4);
M.setSolverParam('mioTolAbsGap', 0.0);

M.objective('obj', ObjectiveSense.Maximize, Expr.dot(c, x));

init_sol =[0.0, 2.0, 0.0, 0.0];
x.setLevel( init_sol );

M.solve();

ss = M.getPrimalSolutionStatus();
display(ss);
sol = x.level();
xx = sprintf('%d ', sol);
fprintf('x = %s', xx);
fprintf('\nMIP rel gap = %.2f (%f)', M.getSolverDoubleInfo('mioObjRelGap'), ...
        M.getSolverDoubleInfo('mioObjAbsGap'));