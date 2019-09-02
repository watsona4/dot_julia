function alan()
%
% Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.
%
%  File:      alan.m
%
%  Purpose: This file contains an implementation of the alan.gms (as
%  found in the GAMS online model collection) using MOSEK Fusion. 
%
%  The model is a simple portfolio choice model. The objective is to
%  invest in a number of assets such that we minimize the risk, while
%  requiring a certain expected return.
%
%  We operate with 4 assets (hardware,software, show-biz and treasure
%  bill). The risk is defined by the covariance matrix
%    Q = [[  4.0, 3.0, -1.0, 0.0 ],
%         [  3.0, 6.0,  1.0, 0.0 ],
%         [ -1.0, 1.0, 10.0, 0.0 ],
%         [  0.0, 0.0,  0.0, 0.0 ]]
% 
%
%  We use the form Q = U'*U, where U is a Cholesky factor of Q.
%
   
import mosek.fusion.*

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%/
% Problem data.
% Security names
securities = [ 'hardware', 'software', 'show-biz', 't-bills' ];
% Mean returns on securities
meanreturn = [        8.0;        9.0;       12.0;       7.0 ];
% Target mean return
target     = 10.0;

% Factor of covariance matrix.
U_data = [ 2.0       ,  1.5       , -0.5        ,  0.0  ; ...
           0.0       ,  1.93649167,  0.90369611 ,  0.0  ; ...
           0.0       ,  0.0       ,  2.98886824 ,  0.0  ; ...
           0.0       ,  0.0       ,  0.0        ,  0.0  ]; 

numsec = size(meanreturn,1);
U      = Matrix.dense(U_data);

M = Model('alan');
x = M.variable('x', numsec,   Domain.greaterThan(0.0));
v = M.variable('variance', 1, Domain.greaterThan(0.0));
w = M.variable('w', 1,        Domain.equalsTo(1.0));
t = M.variable('t', 1,        Domain.unbounded());

% sum securities to 1.0
M.constraint('wealth',  Expr.sum(x), Domain.equalsTo(1.0));
% define target expected return 
M.constraint('dmean', Expr.dot(meanreturn', x), Domain.greaterThan(target));

% (t,0.5,U*x) \in rQcone
M.constraint('cone', Expr.vstack(t, ...
                                 1.0, ...
                                 Expr.mul(U,x)), ...
             Domain.inRotatedQCone());

M.objective('minvar', ObjectiveSense.Minimize, t);

disp('Solve...');
M.solve();
disp('... Solved.');

solx = x.level();
disp([ 'Solution = ' mat2str(solx) ]);