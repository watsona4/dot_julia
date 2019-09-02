%%
%%  Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.
%%
%%  File:      tsp.m
%%
%%  Purpose: Demonstrates a simple technique to the TSP
%%           usign the Fusion API.
%%
function tsp()
  import mosek.fusion.*;
  A_i = [1,2,3,4,2,1,3,1]
  A_j = [2,3,4,1,1,3,2,4]
  C_v = [1.,1.,1.,1.,0.1,0.1,0.1,0.1]

  n= max(max(A_i),max(A_j))
  x = tsp_fusion(n, Matrix.sparse(n,n,A_i,A_j,1.), Matrix.sparse(n,n,A_i,A_j,C_v) , true, true)
  x = tsp_fusion(n, Matrix.sparse(n,n,A_i,A_j,1.), Matrix.sparse(n,n,A_i,A_j,C_v) , true, false)
end

function solution = tsp_fusion(n, A, C, remove_loops, remove_2_hop_loops)
  import mosek.fusion.*;
  M = Model();

  x = M.variable(Set.make(n,n), Domain.binary());

  M.constraint(Expr.sum(x,0), Domain.equalsTo(1.0));
  M.constraint(Expr.sum(x,1), Domain.equalsTo(1.0));
  M.constraint(x, Domain.lessThan( A ));

  M.objective(ObjectiveSense.Minimize, Expr.sum(Expr.mulElm(C, x)));

  if remove_loops == true
    M.constraint(x.diag(), Domain.equalsTo(0.));
  end

  if remove_2_hop_loops == true
    M.constraint(Expr.add(x, x.transpose()), Domain.lessThan(1.0));
  end

  it = 0;
  solution = [];
  not_done = 1;

  while not_done
    it = it + 1
    fprintf('\n\n--------------------\nIteration',it);
    M.solve();

    fprintf('\nsolution cost: %f', M.primalObjValue());
              
    sol = reshape(x.level(), n, n);

    start = 1
    fprintf('looking for cycles...')
    
    while length( find(sol>0.5) ) > 0
       
      cycle = zeros(n,n);
      i = start;

      while true
        xi = sol(i,:);
        j = find(xi>0.5);

        if length(j) == 1
            cycle (i,j) = 1;
            sol(i,j) = 0;
            if start == j
              break
            end
            i = j;
        else
           i = i+1;
           start = i;
        end
      end
      
      [ I, J ]= ind2sub([n,n],find(cycle>0.5));
      cycle
      if length(I) == n
        not_done = 0
        break;
      end
      M.constraint(Expr.sum(x.pick(I, J)), Domain.lessThan(1.0*length(I) - 1 ));
    end
  end
end