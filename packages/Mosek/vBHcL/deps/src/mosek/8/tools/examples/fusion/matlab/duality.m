% Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.
%
% File:      duality.m
% 
% Purpose: Shows how to access the dual values

function duality()

import mosek.fusion.*;

A = [ -0.5, 1 ];
b = [ 1.0 ];
c = [ 1.0, 1.0 ]';

M = Model('duality');
x = M.variable('x', 2, Domain.greaterThan(0.0));

con = M.constraint(Expr.sub(Expr.mul(Matrix.dense(A), x),b), Domain.equalsTo(0.0));

M.objective('obj', ObjectiveSense.Minimize, Expr.dot(c, x));
M.solve()

disp(sprintf('x = %s', mat2str(x.level())))
disp(sprintf('s = %s', mat2str(x.dual())))
disp(sprintf('y = %s', mat2str(con.dual())))