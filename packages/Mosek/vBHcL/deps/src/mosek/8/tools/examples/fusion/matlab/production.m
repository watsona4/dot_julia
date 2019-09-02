%
%  Copyright : Copyright (c) MOSEK ApS, Denmark. All rights reserved.
%
%  File :      production.m
%
%  Purpose:   Demonstrates how to solve a  linear
%             optimization problem using the MOSEK API
%             and modify and re-optimize the problem.
%
function production()
import mosek.fusion.*;
c = [ 1.5, 2.5, 3.0 ];
A = [ 2, 4, 3; ...
      3, 2, 3; ...
      2, 3, 2 ];
b = [ 100000.0, 50000.0, 60000.0 ];
numvar = 3;
numcon = 3;

% Create a model and input data
M = Model();
x = M.variable(numvar, Domain.greaterThan(0.0));
con = M.constraint(Expr.mul(A, x), Domain.lessThan(b));
M.objective(ObjectiveSense.Maximize, Expr.dot(c, x));
% Solve the problem
M.solve();
x.level()

%************** Change an element of the A matrix ****************%
con.index(1).add(x.index(1));
M.solve();
x.level()

%*************** Add a new variable ******************************%
% Create a variable and a compound view of all variables
x3 = M.variable(Domain.greaterThan(0.0));
xNew = Var.vstack(x, x3);
% Add to the exising constraint
con.add(Expr.mul(x3, [4, 0, 1]));
% Change the objective to include x3
M.objective(ObjectiveSense.Maximize, Expr.dot([1.5, 2.5, 3.0, 1.0], xNew));
M.solve();
xNew.level()

%**************** Add a new constraint *****************************%
M.constraint(Expr.dot(xNew, [1, 2, 1, 1]), Domain.lessThan(30000.0));
M.solve();
xNew.level()