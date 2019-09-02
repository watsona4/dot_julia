%% 
%   Copyright : Copyright (c) MOSEK ApS, Denmark. All rights reserved.
%
%   File :      callback.m
%
%   Purpose :   To demonstrate how to use the progress 
%               callback. 
%%
function callback()
	import mosek.*;
	import mosek.fusion.*;

	% Create a random large linear problem
    n = 150;
    m = 700;
    A = rand([m,n]);
    b = rand([m,1]);
    c = rand([n,1]);

    M = Model();
	x = M.variable(n, Domain.unbounded());
    M.constraint(Expr.mul(A,x), Domain.lessThan(b));
    M.objective(ObjectiveSense.Maximize, Expr.dot(c, x));

    maxtime = 0.06;

    userCallback = com.mosek.fusion.examples.MatlabCallback(M, maxtime);
    M.setDataCallbackHandler( userCallback );

    M.solve();
end