%%
%  Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.
%
%  File:      sudoku.m
%
%  Purpose:  A MILP-based SUDOKU solver
%%

function sudoku()

import mosek.fusion.*;

m= 3;
n= m*m;

hr_fixed= [ 1,5,4; ...
            2,2,5; 2,3,8; 2,6,3; ...
            3,2,1; 3,4,2; 3,5,8; 3,7,9; ...
            4,2,7; 4,3,3; 4,4,1; 4,7,8; 4,8,4; ...
            6,2,4; 6,3,1; 6,6,9; 6,7,2; 6,8,7; ...
            7,3,4; 7,5,6; 7,6,5; 7,8,8; ...
            8,4,4; 8,7,1; 8,8,6; ...
            9,5,9
          ];


M= Model('SUDOKU');

x= M.variable([n,n,n], Domain.binary());

%each value only once per dim
for d = 1:m
    M.constraint(Expr.sum(x,d-1), Domain.equalsTo(1.));
end

%each number must appears only once in a block
for k = 1:n
    for i = 1:m 
        for j = 1:m
            M.constraint( Expr.sum( x.slice([1+(i-1)*m,1+(j-1)*m,k], [1+i*m, 1+j*m, k+1]) ), ...
                          Domain.equalsTo(1.) );
        end
    end
end

M.constraint( x.pick(hr_fixed), Domain.equalsTo(1.0) );
    
M.setLogHandler(java.io.PrintWriter(java.lang.System.out)); 
M.solve();

%print the solution, if any...
if M.getPrimalSolutionStatus() == SolutionStatus.Optimal || ...
   M.getPrimalSolutionStatus() == SolutionStatus.NearOptimal
    
    fprintf('\n');
    for i = 1:n
        fprintf(' |');
        for j = 1:n

            for k = 1:n
                if x.index([i,j,k]).level()>0.5
                    fprintf(' %d', k)
                    break;
                end
            end
            if mod(j,m) == 0
                fprintf(' |');
            end

        end
        fprintf('\n');
        if mod(i,m) == 0
            fprintf('\n');
        end

    end
else
  fprintf('No solution found!\n');
end
          
M.dispose()