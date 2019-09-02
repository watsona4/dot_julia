%
%  Copyright : Copyright (c) MOSEK ApS, Denmark. All rights reserved.
%
%  File :      go2.m
%
%  Purpose : Demonstrates a simple geometric optimization problem.
%

function go2()
c     = [1 1 3 1 1 0.1 1/3]';
a     = sparse([[-1  1  0];
                [2 -0.5 0];
                [0 0.5 -1];
                [1 -1 -2]; 
                [-1 1 2]; 
                [-1 0 0]; 
                [1 0 0]]);

map   = [0 1 1 2 3 4 5]';
[res] = mskgpopt(c,a,map);

fprintf('\nPrimal optimal solution to original gp:');
fprintf(' %e',exp(res.sol.itr.xx));
fprintf('\n\n');

% Compute the optimal objective value and
% the constraint activities.
v = c.*exp(a*res.sol.itr.xx);

% Add appropriate terms together.
f = sparse(map+1,1:7,ones(size(map)))*v;

% First objective value. Then constraint values.
fprintf('Objective value: %e\n',log(f(1)));
fprintf('Constraint values:');
fprintf(' %e',log(f(2:end)));
fprintf('\n\n');

% Dual multipliers (should be negative)
fprintf('Dual variables (should be negative):');
fprintf(' %e',res.sol.itr.y);
fprintf('\n\n');