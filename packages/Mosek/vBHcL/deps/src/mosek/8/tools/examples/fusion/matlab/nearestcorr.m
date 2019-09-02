%%
%  Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.
%
%  File:      nearestcorr.m
%
%  Purpose: 
%  Solves the nearest correlation matrix problem
% 
%    minimize   || A - X ||_F   s.t.  diag(X) = e, X is PSD
%
%  as the equivalent conic program
%
%    minimize     t
%   
%    subject to   (t, vec(A-X)) in Q
%                 diag(X) = e
%                 X >= 0

function nearestcorr()
import mosek.fusion.*;
N = 5;
A = [  0.0,  0.5,  -0.1,  -0.2,   0.5;
       0.5,  1.25, -0.05, -0.1,   0.25;
       -0.1, -0.05,  0.51,  0.02, -0.05;
       -0.2, -0.1,   0.02,  0.54, -0.1;
       0.5,  0.25, -0.05, -0.1,   1.25 ];

nearestcorr_frobenius(A,N)

gammas = [0.0:0.1:1.0];
nearestcorr_nucnorm(A,N,gammas)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function nearestcorr_nucnorm(A, N, gammas)

import mosek.fusion.*;
M = Model('NucNorm');

% Setup variables
t = M.variable('t', 1, Domain.unbounded());
X = M.variable('X', Domain.inPSDCone(N));
w = M.variable('w', N, Domain.greaterThan(0.0));

% (t, vec (X + diag(w) - A)) in Q
D = Expr.mulElm( Matrix.eye(N), Var.repeat(w,1,N) );
M.constraint( Expr.vstack( t, vec(Expr.sub(Expr.add(X, D), Matrix.dense(A))) ), ...
              Domain.inQCone() );

% Trace of X
TX = Expr.sum(X.diag());

for g=gammas
    % Objective: Minimize t + gamma*Tr(X)
    M.objective(ObjectiveSense.Minimize, Expr.add(t, Expr.mul(g,TX)));
    M.solve()

    %Get the eigenvalues of X and approximate its rank
    d = eig(reshape(X.level(),N,N));

    disp(sprintf('gamma=%f, res=%e, rank=%d', g, t.level(), sum(d>1e-6)))
end
M.dispose();

function nearestcorr_frobenius(A,N)

import  mosek.fusion.*;
M = Model('NearestCorrelation');

% Setting up the variables
X = M.variable('X', Domain.inPSDCone(N));
t = M.variable('t', 1, Domain.unbounded());

% (t, vec (A-X)) \in Q
M.constraint( Expr.vstack(t, vec(Expr.sub(A,X))), Domain.inQCone() );

% diag(X) = e
M.constraint(X.diag(), Domain.equalsTo(1.0));

% Objective: minimize t
M.objective(ObjectiveSense.Minimize, t);
M.solve();

% Get the solution values
reshape(X.level(), N,N)
M.dispose();


% Assuming that e is an NxN expression, return the lower triangular part as a vector.
function r = vec(e)

import mosek.fusion.*;

N = e.getShape().dim(1);

subi = [1: N*(N+1)/2];
subj = zeros(N*(N+1)/2,1);
val  = zeros(N*(N+1)/2,1);

k=1;
for j=1:N,
    for i=j:N,
        subj(k) = i+(j-1)*N;
        if (i==j),
            val(k) = 1;
        else
            val(k) = sqrt(2);
        end;
        k = k + 1;
    end        
end

S = Matrix.sparse(N*(N+1)/2, N*N, subi, subj, val);
r = Expr.mul(S, Expr.reshape( e, N*N ));