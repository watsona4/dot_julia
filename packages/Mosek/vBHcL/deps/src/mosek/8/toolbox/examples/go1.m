%%
%
%  Copyright : Copyright (c) MOSEK ApS, Denmark. All rights reserved.
%
%  File :      go1.m
%
%  Purpose : Demonstrates a simple geometric optimization problem.
%
%%

function go1()

c     = [40 20 40 1/3 4/3]';
a     = sparse([[-1  -0.5  -1];[1 0 1];...
                [1 1 1];[-2 -2 0];[0 0.5 -1]]);
map   = [0 0 0 1 1]';
[res] = mskgpopt(c,a,map);

fprintf('\nPrimal optimal solution to original gp:');
fprintf(' %e',exp(res.sol.itr.xx));
fprintf('\n\n');

% Compute the optimal objective value and
% the constraint activities.
v = c.*exp(a*res.sol.itr.xx);

% Add appropriate terms together.
f = sparse(map+1,1:5,ones(size(map)))*v;

% First objective value. Then constraint values.
fprintf('Objective value: %e\n',log(f(1)));
fprintf('Constraint values:');
fprintf(' %e',log(f(2:end)));
fprintf('\n\n');

% Dual multipliers (should be negative)
fprintf('Dual variables (should be negative):');
fprintf(' %e',res.sol.itr.y);
fprintf('\n\n');