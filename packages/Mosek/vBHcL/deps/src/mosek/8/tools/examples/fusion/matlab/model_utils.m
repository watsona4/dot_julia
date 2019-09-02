%%
%  Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.
%
%  File:      model_utils.m
%
%  Purpose: Models the geometric mean and n-th root of determinant
classdef model_utils
    
    methods (Static)

        %Models the convex set 
        %
        %  S = { (x, t) \in R^n x R | x >= 0, t <= (x1 * x2 * ... * xn)^(1/n) }
        %
        %as  the intersection of rotated quadratic cones and affine hyperplanes.
        %see [1, p. 105] or [2, p. 21].  This set can be interpreted as the hypograph of the 
        %geometric mean of x.
        %
        %We illustrate the modeling procedure using the following example.
        %Suppose we have 
        %
        %   t <= (x1 * x2 * x3)^(1/3)
        %
        %for some t >= 0, x >= 0. We rewrite it as
        %
        %   t^4 <= x1 * x2 * x3 * x4,   x4 = t
        %
        %which is equivalent to (see [1])
        %
        %   x11^2 <= 2*x1*x2,   x12^2 <= 2*x3*x4,
        %
        %   x21^2 <= 2*x11*x12,
        %
        %   sqrt(8)*x21 = t, x4 = t.
        function geometric_mean(M, x, t)
            import mosek.fusion.*;
            
            n = x.size();
            l = ceil(log2(n));
            m = 2^l - n;
            
            if (m == 0)
                x0 = x;
            else    
                x0 = Variable.vstack(x, M.variable(m, Domain.greaterThan(0.0)));
            end
            
            z = x0;
            
            for i=1:l-1,
                xi = M.variable(2^(l-i), Domain.greaterThan(0.0));
                
                for k=1:2^(l-i),        
                    M.constraint(Variable.hstack( z.index(2*k-1),z.index(2*k),xi.index(k)),...
                                 Domain.inRotatedQCone());
                end
                z = xi;
            end
        
            t0 = M.variable(1, Domain.greaterThan(0.0));
            M.constraint(Var.vstack(z, t0), Domain.inRotatedQCone());
            
            M.constraint(Expr.sub(Expr.mul(2^(0.5*l),t),t0), Domain.equalsTo(0.0));
            for i=2^l-m+1:2^l
                M.constraint(Expr.sub(x0.index(i), t), Domain.equalsTo(0.0));
            end
            
            t0 = M.variable(1, Domain.greaterThan(0.0));
            M.constraint(Var.vstack(z, t0), Domain.inRotatedQCone());
            
            M.constraint(Expr.sub(Expr.mul(2^(0.5*l),t),t0), Domain.equalsTo(0.0));
            for i=2^l-m+1:2^l
                M.constraint(Expr.sub(x0.index(i), t), Domain.equalsTo(0.0));
            end
        
        end

        % Purpose: Models the hypograph of the n-th power of the
        % determinant of a positive definite matrix. See [1,2] for more details.
        %
        %   The convex set (a hypograph)
        %
        %   C = { (X, t) \in S^n_+ x R |  t <= det(X)^{1/n} },
        %
        %   can be modeled as the intersection of a semidefinite cone
        %
        %   [ X, Z; Z^T Diag(Z) ] >= 0  
        %
        %   and a number of rotated quadratic cones and affine hyperplanes,
        %
        %   t <= (Z11*Z22*...*Znn)^{1/n}  (see geometric_mean).
        function [] = det_rootn(M, X, t)

            import mosek.fusion.*;

            n = X.shape.dim(1);

            % Setup variables
            Y = M.variable(Domain.inPSDCone(2*n));
        
            % Setup Y = [X Z; Z^T diag(Z)] 
            Y11 = Y.slice([1,   1],   [n+1,   n+1]);
            Y21 = Y.slice([n+1, 1],   [2*n+1, n+1]);
            Y22 = Y.slice([n+1, n+1], [2*n+1, 2*n+1]);

            S = Matrix.sparse(n, n, 1:n, 1:n, ones(1,n));
            M.constraint( Expr.sub(Y21.diag(), Y22.diag()), Domain.equalsTo(0.0) );
            M.constraint( Expr.sub(X, Y11), Domain.equalsTo(0.0) );
            
            % t^n <= (Z11*Z22*...*Znn)
            model_utils.geometric_mean(M, Y22.diag(), t);
        end
    end

end