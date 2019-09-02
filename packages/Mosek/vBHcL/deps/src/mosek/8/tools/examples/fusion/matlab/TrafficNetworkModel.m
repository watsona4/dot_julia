function TrafficNetworkModel()
%
% Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.
%
% File:      TrafficNetworkModel.m
%
% Purpose:   Demonstrates a traffic network problem as a conic quadratic problem.
%
% Source:    Robert Fourer, 'Convexity Checking in Large-Scale Optimization', 
%            OR 53 --- Nottingham 6-8 September 2011.
%
% The problem: 
%            Given a directed graph representing a traffic network
%            with one source and one sink, we have for each arc an
%            associated capacity, base travel time and a
%            sensitivity. Travel time along a specific arc increases
%            as the flow approaches the capacity. 
%
%            Given a fixed inflow we now wish to find the
%            configuration that minimizes the average travel time.

import mosek.fusion.*;

n        = 4;
arc_i    = [  1.0,  1.0,  3.0,  2.0,  3.0 ];
arc_j    = [  2.0,  3.0,  2.0,  4.0,  4.0 ];
arc_base = [  4.0,  1.0,  2.0,  1.0,  6.0 ];
arc_cap  = [ 10.0, 12.0, 20.0, 15.0, 10.0 ];
arc_sens = [  0.1,  0.7,  0.9,  0.5,  0.1 ];

T          = 20.0;
source_idx = 1;
sink_idx   = 4;

narcs = size(arc_j,2);

NxN      = Set.make(n,n);
sens     = Matrix.sparse(n, n, arc_i, arc_j, arc_sens);
cap      = Matrix.sparse(n, n, arc_i, arc_j, arc_cap);        
basetime = Matrix.sparse(n, n, arc_i, arc_j, arc_base);        
e        = Matrix.sparse(n, n, arc_i, arc_j, ones(narcs,1) );
e_e      = Matrix.sparse(n, n, [ sink_idx ], [source_idx ], [ 1.0 ] );

cs_inv_matrix = Matrix.sparse(n, n, arc_i, arc_j, 1.0 ./ ( arc_sens .* arc_cap));
s_inv_matrix  = Matrix.sparse(n, n, arc_i, arc_j, 1.0 ./ arc_sens);

M = Model('TrafficNetworkModel');

x = M.variable('traffic_flow', NxN, Domain.greaterThan(0.0));

t = M.variable('travel_time' , NxN, Domain.greaterThan(0.0));
d = M.variable('d',            NxN, Domain.greaterThan(0.0));
z = M.variable('z',            NxN, Domain.greaterThan(0.0));

% Set the objective:
M.objective('Average travel time',...
            ObjectiveSense.Minimize,...
            Expr.mul(1.0/T, Expr.add(Expr.dot(basetime,x), Expr.dot(e,d))));

% Set up constraints
% Constraint (1a)
v = javaArray('mosek.fusion.Variable',narcs,3);
for i=1:narcs
  v(i,1) = d.index(arc_i(i),arc_j(i));
  v(i,2) = z.index(arc_i(i),arc_j(i));
  v(i,3) = x.index(arc_i(i),arc_j(i));
end
M.constraint('(1a)', Var.stack(v), Domain.inRotatedQCone(narcs,3));

% Constraint (1b)
M.constraint('(1b)',...
             Expr.sub(Expr.add(Expr.mulElm(z,e),...
                               Expr.mulElm(x,cs_inv_matrix)),...
                      s_inv_matrix),...
             Domain.equalsTo(0.0));

% Constraint (2)
M.constraint('(2)',...
             Expr.sub(Expr.add(Expr.mulDiag(x, e.transpose()),...
                               Expr.mulDiag(x, e_e.transpose())),...
                      Expr.add(Expr.mulDiag(x.transpose(), e),...
                               Expr.mulDiag(x.transpose(), e_e))),...
             Domain.equalsTo(0.0));
% Constraint (3)
M.constraint('(3)',...
             x.index(sink_idx, source_idx), Domain.equalsTo(T));


M.solve();

flow = x.level();

disp('flow =');
disp(flow);
for i=1:narcs
  fprintf(1,'\tflow node%d->node%d = %.2f\n', arc_i(i),arc_j(i),flow(arc_i(i) * n + arc_j(i)));
end

M.dispose();