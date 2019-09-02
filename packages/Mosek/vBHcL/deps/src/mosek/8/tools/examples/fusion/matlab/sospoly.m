%%
%  Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.
%
%  File:      sospoly.m
%
%  Purpose: 
%  Models the cone of nonnegative polynomials and nonnegative trigonometric
%  polynomials using Nesterov's framework  [1].
%
%  Given a set of coefficients (x0, x1, ..., xn), the functions model the 
%  cone of nonnegative polynomials 
%
%  P_m = { x \in R^{n+1} | x0 + x1*t + ... xn*t^n >= 0, forall t \in I }
%
%  where I can be the entire real axis, the semi-infinite interval [0,inf), or
%  a finite interval I = [a, b], respectively.
%
%  References:
%
%  [1] "Squared Functional Systems and Optimization Problems",  
%      Y. Nesterov, in High Performance Optimization,
%      Kluwer Academic Publishers, 2000.
%

classdef sospoly
    
    methods (Static)
        
        function H = Hankel(n, i, a)
        % Creates a Hankel matrix of dimension n+1, where 
        %   H_lk = a if l+k=i, and 0 otherwise.
            import mosek.fusion.*;
            
            if nargin < 3
                a = 1.0;
            end
    
            if i < n+1,
                H = Matrix.sparse(n+1, n+1, 1+[i:-1:0], 1+[0:i], ones(1,i+1)*a);
            else
                H = Matrix.sparse(n+1, n+1, 1+[n:-1:i-n], 1+[i-n:n], ones(1,2*n+1-i)*a);
            end
        end

        function [] = nn_inf(M, x)
        % Models the cone of nonnegative polynomials on the real axis
            import mosek.fusion.*;
            
            m = (x.size() - 1); 
            n = floor(m/2); % degree of polynomial is 2*n
            
            assert(m == 2*n);
                
            % Setup variables
            X = M.variable(Domain.inPSDCone(n+1));

            % x_i = Tr H(n, i) * X  i=0,...,m
            for i=0:m,
                M.constraint( Expr.sub(x.index(i+1), Expr.dot(sospoly.Hankel(n,i),X)), ...
                              Domain.equalsTo(0.0));
            end
        end
        
        function [] = nn_semiinf(M, x);
        % Models the cone of nonnegative polynomials on the semi-infinite interval [0,inf)
            import mosek.fusion.*;

            n  = x.size()-1;
            n1 = floor(n/2);
            n2 = floor((n-1)/2);
    
            % Setup variables
            X1 = M.variable(Domain.inPSDCone(n1+1));
            X2 = M.variable(Domain.inPSDCone(n2+1));

            % x_i = Tr H(n1, i) * X1 + Tr H(n2,i-1) * X2, i=0,...,n
            for i=0:n,
                e1 = Expr.dot(sospoly.Hankel(n1,i),  X1);
                e2 = Expr.dot(sospoly.Hankel(n2,i-1),X2);        
                M.constraint( Expr.sub(x.index(i+1), Expr.add(e1, e2)), Domain.equalsTo(0.0) );
            end
        end
            
        function [] = nn_finite(M, x, a, b)
        % Models the cone of nonnegative polynomials on the finite interval [a,b]
            import mosek.fusion.*;

            assert(a < b)            
            m = x.size()-1;
            n = floor(m/2);
            
            if (m == 2*n)        
                X1 = M.variable(Domain.inPSDCone(n+1));
                X2 = M.variable(Domain.inPSDCone(n));
                
                % x_i = Tr H(n,i)*X1 + (a+b)*Tr H(n-1,i-1) * X2 - a*b*Tr H(n-1,i)*X2 - Tr H(n-1,i-2)*X2, i=0,...,m
                for i=0:m,
                    e1 = Expr.sub(Expr.dot(sospoly.Hankel(n, i),  X1), ...
                                  Expr.dot(sospoly.Hankel(n-1, i, a*b), X2));
                    e2 = Expr.sub(Expr.dot(sospoly.Hankel(n-1, i-1, a+b), X2), ...
                                  Expr.dot(sospoly.Hankel(n-1, i-2),  X2));
                    M.constraint( Expr.sub(x.index(i+1), Expr.add(e1, e2)), Domain.equalsTo(0.0) );
                end                                
            else                
                X1 = M.variable(Domain.inPSDCone(n+1));
                X2 = M.variable(Domain.inPSDCone(n+1));

                % x_i = Tr H(n,i-1)*X1 - a*Tr H(n,i)*X1 + b*Tr H(n,i)*X2 - Tr H(n,i-1)*X2, i=0,...,m
                for i=0:m,
                    e1 = Expr.sub(Expr.dot(sospoly.Hankel(n, i-1),  X1), ...
                                  Expr.dot(sospoly.Hankel(n, i, a), X1));
                    e2 = Expr.sub(Expr.dot(sospoly.Hankel(n, i, b), X2), ...
                                  Expr.dot(sospoly.Hankel(n, i-1),  X2));
                    M.constraint( Expr.sub(x.index(i+1), Expr.add(e1, e2)), Domain.equalsTo(0.0) );
                end
            end
        end

        function u = diff(M, x)
        % returns variables u representing the derivative of
        %   x(0) + x(1)*t + ... + x(n)*t^n,
        % with u(0) = x(1), u(1) = 2*x(2), ..., u(n-1) = n*x(n).
            import mosek.fusion.*;
            
            n  = x.size()-1;
            u = M.variable(n, Domain.unbounded());

            tmp = Variable.reshape(x.slice(2,n+2),Set.make(1,n));
            M.constraint(Expr.sub(u, Expr.mulElm(matrix.Dense([1:n]), tmp)), ...
                         Domain.equalsTo(0.0));            
        end
                   
        function x = fitpoly(data, n)
            import mosek.fusion.*;
            
            M = Model('smooth poly');
            
            m = size(data,1);
            A   = repmat(data(:,1),1,n+1).^(ones(m,1)*[0:n]);
            b   = data(:, 2);
            
            x  = M.variable('x', n+1, Domain.unbounded());
            z  = M.variable('z', 1, Domain.unbounded());
            dx = sospoly.diff(M, x);
                       
            M.constraint(Expr.mul(Matrix.dense(A), x), Domain.equalsTo(b));
                        
            % z - f'(t) >= 0, for all t \in [a, b]
            ub = M.variable(n, Domain.unbounded);
            M.constraint(Expr.sub(ub, ...
                                  Expr.vstack(Expr.sub(z,dx.index(1)), dx.slice(2,n+1).asExpr().neg())), ...
                         Domain.equalsTo(0.0));            
            sospoly.nn_finite(M, ub, data(1,1), data(m,1))

            % f'(t) + z >= 0, for all t \in [a, b]
            lb = M.variable(n, Domain.unbounded());
            M.constraint(Expr.sub(lb, ...
                                  Expr.vstack(Expr.add(z, dx.index(1)), dx.slice(2,n+1).asExpr())), ...
                         Domain.equalsTo(0.0));            
            sospoly.nn_finite(M, lb, data(1,1), data(m,1))
           
            M.objective(ObjectiveSense.Minimize, z);
            M.solve();
            x = x.level();
            M.dispose();            
        end
                    
        function [] = main()
            import mosek.fusion.*;
            
            data = [ -1.0, 1.0; ...
                      0.0, 0.0; ...
                      1.0, 1.0; ];
            
            x2 = sospoly.fitpoly(data, 2)
            x4 = sospoly.fitpoly(data, 4)
            x8 = sospoly.fitpoly(data, 8)
            
            a = -2;
            b =  2;
            I = [a:(b-a)/100:b]';
            plot(data(:,1), data(:,2), 'o')
            hold on
            plot(I, sospoly.evalpoly(x2, I))
            plot(I, sospoly.evalpoly(x4, I),'r')
            plot(I, sospoly.evalpoly(x8, I),'k')
            hold off         
            axis([a, b, -0.1, 2])
        end
        
        function y = evalpoly(x, I)
            m = length(I);
            n = length(x) - 1;
            V = repmat(I,1,n+1).^(ones(m,1)*[0:n]);
            y = V*x;
        end
        
    end    
end