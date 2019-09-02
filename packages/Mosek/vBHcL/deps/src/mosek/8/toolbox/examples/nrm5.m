%
%  Copyright : Copyright (c) MOSEK ApS, Denmark. All rights reserved.
%
%  File :      nrm5.m
%
%  Purpose:    Solve a linear least squares subject to bound
%              constraints:
%
%              minimize 1/2 || Fx - f ||_2
%
%                       l_x <= x <= u_x
%
%              first reformulated as
%
%              minimize 1/2 ||y||^2
%
%                       Fx - f  = y
%                       l_x <= x <= u_x
%

function nrm5()
F = repmat( [ [ 0.4302, 0.3516 ]; [0.6246, 0.3384] ], 10, 1);
f = repmat( [ 0.6593, 0.9666]', 10,1) ;
% Obtain the matrix dimensions.
[m,n]   = size(F)

prob        = [];

prob.qosubi = n+(1:m);
prob.qosubj = n+(1:m);
prob.qoval  = ones(m,1);
prob.a      = [ F,-speye(m,m)];
prob.blc    = f;
prob.buc    = f;
blx         = -ones(n,1);
bux         =  ones(n,1);
prob.blx    = [blx;-inf*ones(m,1)];
prob.bux    = [bux; inf*ones(m,1)];

fprintf('m=%d  n=%d\n',m,n);

fprintf('First try\n');

tic
[rcode,res] = mosekopt('minimize',prob);

% Display the solution time.
fprintf('Time           : %-.2f\n',toc);

try 
  % x solution:
  x = res.sol.itr.xx;

  % objective value:
  fprintf('Objective value: %-6e\n', 0.5*norm(F*x(1:n)-f)^2);

  % Check feasibility.
  fprintf('Feasibility    : %-6e\n',min(x(1:n)-blx(1:n)));
catch
  fprintf('MSKERROR: Could not get solution')
end

% Clear prob.
prob=[];

%
% Next, we solve the dual problem.

% Index of lower bounds that are finite:
lfin        = find(blx>-inf);

% Index of upper bounds that are finite:
ufin        = find(bux<inf);

prob.qosubi = 1:m;
prob.qosubj = 1:m;
prob.qoval  = -ones(m,1);
prob.c      = [f;blx(lfin);-bux(ufin)];
prob.a      = [F',...
               sparse(lfin,(1:length(lfin))',...
                      ones(length(lfin),1),...
                      n,length(lfin)),...
               sparse(ufin,(1:length(ufin))',...
                      -ones(length(ufin),1),...
                      n,length(ufin))];
prob.blc    = sparse(n,1);
prob.buc    = sparse(n,1);
prob.blx    = [-inf*ones(m,1);...
               sparse(length(lfin)+length(ufin),1)];
prob.bux    = [];

fprintf('\n\nSecond try\n');
tic
[rcode,res] = mosekopt('maximize',prob);

% Display the solution time.
fprintf('Time           : %-.2f\n',toc);

try
  % x solution:
  x = res.sol.itr.y

  % objective value:
  fprintf('Objective value: %-6e\n',...
          0.5*norm(F*x(1:n)-f)^2);

  % Check feasibility.
  fprintf('Feasibility    : %-6e\n',...
          min(x(1:n)-blx(1:n)));
catch
  fprintf('MSKERROR: Could not get solution')
end
