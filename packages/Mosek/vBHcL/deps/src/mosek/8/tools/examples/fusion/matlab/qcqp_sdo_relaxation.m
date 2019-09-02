%%
% Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.
%
% File:      qcqp_sdo_relaxation.m
%
% Purpose:   Demonstrate how to use SDP to solve
%            convex relaxation of a mixed-integer QCQP 
%%

function qcqp_sdo_relaxation()
import mosek.fusion.*;
% problem dimensions
n = 20  ;
m = 2*n ;

% problem data
A = randn([m,n]);
c = rand([n,1]);
P = A' * A;
q = -P*c;
b = A*c;

% solve the problems
M = miqcqp_sdo_relaxation(n, P, q);
Mint = int_least_squares(n, A, b);

M.solve();
Mint.solve();

% rounded and optimal solution
xRound = round(M.getVariable('Z').slice([1,n+1], [n+1,n+2]).level());
xOpt = round(Mint.getVariable('x').level());

M.getSolverDoubleInfo('optimizerTime'), Mint.getSolverDoubleInfo('optimizerTime')
norm(A*xRound-b), norm(A*xOpt-b)
end

% The relaxed SDP model
function M = miqcqp_sdo_relaxation(n,P,q)
	import mosek.fusion.*;
    M = Model();

    Z = M.variable('Z', n+1, Domain.inPSDCone());
    X = Z.slice([1,1], [n+1,n+1]);
    x = Z.slice([1,n+1], [n+1,n+2]);

    M.constraint( Expr.sub(X.diag(), x), Domain.greaterThan(0.) );
    M.constraint( Z.index(n+1,n+1), Domain.equalsTo(1.) );

    M.objective( ObjectiveSense.Minimize, Expr.add(... 
        Expr.sum( Expr.mulElm( P, X ) ), ...
        Expr.mul( 2.0, Expr.dot(x, q) )  ...
    ) );
end

% A direct integer model for minimizing |Ax-b|
function M = int_least_squares(n, A, b)
	import mosek.fusion.*;
    M = Model();

    x = M.variable('x', n, Domain.integral(Domain.unbounded()));
    t = M.variable('t', 1, Domain.unbounded());

    M.constraint( Expr.vstack(t, Expr.sub(Expr.mul(A, x), b)), Domain.inQCone() );
    M.objective( ObjectiveSense.Minimize, t );
end