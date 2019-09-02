function baker()
%
% Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.
%
% File:      baker.m
%
% Purpose: Demonstrates a small linear problem.
%
% Source: 'Linaer Algebra' by Knut Sydsaeter and Bernt Oeksendal.
%
% The problem: A baker has 150 kg flour, 22 kg sugar, 25 kg butter and two 
% recipes:
%   1) Cakes, requiring 3.0 kg flour, 1.0 kg sugar and 1.2 kg butter per dozen.
%   2) Breads, requiring 5.0 kg flour, 0.5 kg sugar and 0.5 kg butter per dozen.
% Let the revenue per dozen cakes be $4 and the revenue per dozen breads be $6.
% 
% We now wish to compute the combination of cakes and breads that will optimize 
% the total revenue.

import mosek.fusion.*;


ingredientnames = { 'Flour', 'Sugar', 'Butter' };
stock           = [ 150.0,   22.0,    25.0 ];
recipe_data     = [ 3.0, 5.0 ;
                    1.0, 0.5 ;,
                    1.2, 0.5 ];
productnames    = { 'Cakes', 'Breads' };
revenue         = [ 4.0, 6.0 ];

recipe = Matrix.dense(recipe_data);
M = Model('Recipe');
% 'production' defines the amount of each product to bake.
production = M.variable('production', StringSet(productnames), Domain.greaterThan(0.0));
% The objective is to maximize the total revenue.
 
M.objective('revenue', ObjectiveSense.Maximize, Expr.dot(revenue, production));
% The prodoction is constrained by stock:
M.constraint(Expr.mul(recipe, production), Domain.lessThan(stock));
M.setLogHandler(java.io.PrintWriter(java.lang.System.out));

% We solve and fetch the solution:
M.solve();
res = production.level();

disp( 'Solution: ')
for i=1:2, ...
  fprintf(1,' Number of %s : %d\n', productnames{i}, res(i));
end
fprintf(1,' Revenue : $%.2f\n', res(1) * revenue(1) + res(2) * revenue(2));