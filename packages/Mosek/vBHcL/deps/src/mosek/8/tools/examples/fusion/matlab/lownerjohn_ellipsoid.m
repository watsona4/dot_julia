%%
%  Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.
%
%  File:      lownerjohn_ellipsoid.m
%
%  Purpose: 
%  Computes the Lowner-John inner and outer ellipsoidal 
%  approximations of a polytope.
%
%
%  The inner ellipsoidal approximation to a polytope 
%
%     S = { x \in R^n | Ax < b }.
%
%  maximizes the volume of the inscribed ellipsoid,
%
%     { x | x = C*u + d, || u ||_2 <= 1 }.
%
%  The volume is proportional to det(C)^(1/n), so the
%  problem can be solved as 
%
%    maximize         t
%    subject to       t       <= det(C)^(1/n)
%                || C*ai ||_2 <= bi - ai^T * d,  i=1,...,m
%                  C is PSD
%
%  which is equivalent to a mixed conic quadratic and semidefinite
%  programming problem.
%
%
%  The outer ellipsoidal approximation to a polytope given 
%  as the convex hull of a set of points
%
%      S = conv{ x1, x2, ... , xm }
%
%  minimizes the volume of the enclosing ellipsoid,
%
%    { x | || P*x-c ||_2 <= 1 }
%
%  The volume is proportional to det(P)^{-1/n}, so the problem can
%  be solved as
%
%    minimize         t
%    subject to       t       >= det(P)^(-1/n)
%                || Px - c ||_2 <= 1
%                  P is PSD.
%
%  References:
%  [1] "Lectures on Modern Optimization", Ben-Tal and Nemirovski, 2000. 
%  [2] "MOSEK modeling manual", 2013
%

classdef lownerjohn_ellipsoid

    methods (Static)

        function [C, d] = lownerjohn_inner(A, b)
        
            import mosek.fusion.*;
        
            M = Model('lownerjohn_inner');
        
            [m, n] = size(A);  

            % Setup variables
            t = M.variable('t', 1, Domain.greaterThan(0.0));
            C = M.variable('C', Domain.inPSDCone(n));
            d = M.variable('d', n, Domain.unbounded());
        
            % (b-Ad, AC) generate cones 
            M.constraint('qc', Expr.hstack(Expr.sub(b, Expr.mul(A,d)), Expr.mul(A,C.transpose())), Domain.inQCone());
            
            % t <= det(C)^{1/n}
            model_utils.det_rootn(M, C, t);
            
            % Objective: Maximize t
            M.objective(ObjectiveSense.Maximize, t);
            
            M.solve();
            
            C = reshape(C.level(), n, n);
            d = reshape(d.level(), n, 1);
    
            M.dispose();
        end
        
        function [P, c] = lownerjohn_outer(x)
    
            import mosek.fusion.*;
    
            M = Model('lownerjohn_outer');
            
            [m, n] = size(x);  
    
            % Setup variables
            t = M.variable('t', 1, Domain.greaterThan(0.0));
            P = M.variable('P', Domain.inPSDCone(n));    
            c = M.variable('c', n, Domain.unbounded());
    
            % (1, Px-c) \in Q 
            M.constraint('qc', ...
                         Expr.hstack(Expr.ones(m), ...
                                     Expr.sub(Expr.mul(x,P.transpose()), ...
                                              Var.reshape(Var.repeat(c,m), [m,n]))), ...
                         Domain.inQCone());

            % t <= det(P)^{1/n}
            model_utils.det_rootn(M, P, t);
        
            % Objective: Maximize t
            M.objective(ObjectiveSense.Maximize, t);
            M.solve();
    
            P = reshape(P.level(), n, n);
            c = reshape(c.level(), n, 1);
            
            M.dispose();
        end

        function plot_ellipse(C, d)

            N = 50;
            theta = 2*pi*[0:N-1]/(N-1);
            
            U = [cos(theta); sin(theta)];
            X = C*U + d*ones(1,N);
            plot(X(1,:),X(2,:));
            
        end
        
        function main()
            import  mosek.fusion.*;
            
            % Vertices of a polygon in R^2
            p = [ 0.,0.; 1.,3.; 5.5,4.5; 7.,4.; 7.,1.; 3.,-2. ];
            m = length(p);
            
            % The h-representation of that polygon
            A = zeros(m, 2);
            b = zeros(m, 1);
            
            A(1,:) = [ -p(1,2)+p(m,2), p(1,1)-p(m,1) ];
            b(1)   = A(1,:)*p(1,:)';
            for i=2:size(p,1),  
                A(i,:) = [ -p(i,2)+p(i-1,2), p(i,1)-p(i-1,1) ];
                b(i)   = A(i,:)*p(i,:)';    
            end;
 
            [Ci, di] = lownerjohn_ellipsoid.lownerjohn_inner(A, b)
            [Po, co] = lownerjohn_ellipsoid.lownerjohn_outer(p)
            
            plot([p(:,1); p(1,1)],[p(:,2); p(1,2)],'*-');
            axis equal
            hold on
            lownerjohn_ellipsoid.plot_ellipse(Ci, di)
            lownerjohn_ellipsoid.plot_ellipse(inv(Po), Po\co)
            hold off
            
        end

    end
    
end
