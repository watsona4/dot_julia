%%
%  Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.
%
%  File:      lpt.m
%
%  Purpose:  Demonstrates how to solve the multi-processor
%            scheduling problem using the Fusion API.
%%

function lpt()

import mosek.fusion.*;

n = 30;               %Number of tasks
m = 6;                %Number of processors

lb = 1.0;             %The range of lengths of short tasks
ub = 5.0;
sh = 0.8;             %The proportion of short tasks
n_short = floor(n*sh);
n_long = n-n_short;

rng(0);
T= sort([rand([n_short,1])*(ub-lb)+lb; 20*(rand([n_long,1])*(ub-lb)+lb)], 'descend');

fprintf('jobs: %d\n',n);
fprintf('machines: %d\n',m);

M= Model('Multi-processor scheduling');

x= M.variable('x', [m,n], Domain.binary());
t= M.variable('t',1);

M.constraint( Expr.sum(x,0), Domain.equalsTo(1.) );
M.constraint( Expr.sub( Var.repeat(t,m), Expr.mul(x,T) ), Domain.greaterThan(0.) );

M.objective( ObjectiveSense.Minimize, t );

%LPT heuristic
schedule= zeros([m,1]);
init= zeros([m*n,1]);

for i = 1:n
    [val,indx]= min(schedule);
    schedule(indx) = schedule(indx) + T(i);
    init(n*(indx-1) + i)=1.0;
end

%Comment this line to switch off feeding in the initial LPT solution  
x.setLevel(init);

M.setLogHandler(java.io.PrintWriter(java.lang.System.out));
M.setSolverParam('mioTolRelGap', .1);
M.solve();

fprintf('initial solution:\n');
for i = 1:m
   fprintf('M %d: ',i);
   for j = 1:n
       fprintf('%f, ', init((i-1)*n+j) );
   end
   fprintf('\n');
end

fprintf('MOSEK solution:\n');
for i = 1:m
   fprintf('M %d: ',i);
   for j = 1:n
       value= x.index(i,j).level();
       fprintf('%f, ', value(1) );
   end
   fprintf('\n');
end

M.dispose();