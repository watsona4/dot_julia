function [Xres] = sdo1()
%%
%  Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.
%
%  File:      sdo1.m
%
%  Solves the semidefinite optimization problem
%
%                   [2, 1, 0]   
%    minimize    Tr [1, 2, 1] * X + x1
%                   [0, 1, 2]
%
%                   [1, 0, 0]
%    subject to  Tr [0, 1, 0] * X + x1 = 1
%                   [0, 0, 1]
%
%                   [1, 1, 1]
%                Tr [1, 1, 1] * X + x2 + x3 = 0.5
%                   [1, 1, 1]
%
%                   X is PSD, (x1,x2,x3) in quad. cone.
import mosek.fusion.*;

M = Model('sdo1');

% Setting up the variables
X  = M.variable('X', Domain.inPSDCone(3));
x  = M.variable('x', Domain.inQCone(3));

% Setting up constant coefficient matrices
C  = Matrix.dense( [[2.,1.,0.]; [1.,2.,1.]; [0.,1.,2.]] );
A1 = Matrix.eye(3);
A2 = Matrix.ones(3,3);

% Objective
M.objective(ObjectiveSense.Minimize, Expr.add(Expr.dot(C, X), x.index(1)));

% Constraints
M.constraint('c1', Expr.add(Expr.dot(A1, X), x.index(1)), Domain.equalsTo(1.0));
M.constraint('c2', Expr.add(Expr.dot(A2, X), Expr.sum(x.slice(2, 4))), Domain.equalsTo(0.5));

M.solve();

X.level()
x.level()