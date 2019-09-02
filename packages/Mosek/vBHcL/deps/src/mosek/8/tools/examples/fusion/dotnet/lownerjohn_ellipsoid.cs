/*
   Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.

   File:      lownerjohn_ellipsoid.cs

   Purpose:
   Computes the Lowner-John inner and outer ellipsoidal
   approximations of a polytope.


   The inner ellipsoidal approximation to a polytope

      S = { x \in R^n | Ax < b }.

   maximizes the volume of the inscribed ellipsoid,

      { x | x = C*u + d, || u ||_2 <= 1 }.

   The volume is proportional to det(C)^(1/n), so the
   problem can be solved as

     maximize         t
     subject to       t       <= det(C)^(1/n)
                 || C*ai ||_2 <= bi - ai^T * d,  i=1,...,m
                   C is PSD

   which is equivalent to a mixed conic quadratic and semidefinite
   programming problem.


   The outer ellipsoidal approximation to a polytope given
   as the convex hull of a set of points

       S = conv{ x1, x2, ... , xm }

   minimizes the volume of the enclosing ellipsoid,

     { x | || P*(x-c) ||_2 <= 1 }

   The volume is proportional to det(P)^{-1/n}, so the problem can
   be solved as

     minimize         t
     subject to       t       >= det(P)^(-1/n)
                 || P*xi + c ||_2 <= 1,  i=1,...,m
                   P is PSD.

   References:
   [1] "Lectures on Modern Optimization", Ben-Tal and Nemirovski, 2000.
 */

using System;

namespace mosek.fusion.example
{
  public class lownerjohn_ellipsoid
  {
    /**
        Purpose: Models the convex set

          S = { (x, t) \in R^n x R | x >= 0, t <= (x1 * x2 * ... *xn)^(1/n) }.

        as the intersection of rotated quadratic cones and affine hyperplanes,
        see [1, p. 105].  This set can be interpreted as the hypograph of the
        geometric mean of x.

        We illustrate the modeling procedure using the following example.
        Suppose we have

           t <= (x1 * x2 * x3)^(1/3)

        for some t >= 0, x >= 0. We rewrite it as

           t^4 <= x1 * x2 * x3 * x4,   x4 = t

        which is equivalent to (see [1])

           x11^2 <= 2*x1*x2,   x12^2 <= 2*x3*x4,

           x21^2 <= 2*x11*x12,

           sqrt(8)*x21 = t, x4 = t.

        References:
        [1] "Lectures on Modern Optimization", Ben-Tal and Nemirovski, 2000.
    */
    public static void geometric_mean(Model M, Variable x, Variable t)
    {
      int n = (int)x.Size();
      int l = (int)System.Math.Ceiling(log2(n));
      int m = pow2(l) - n;

      Variable x0;

      if (m == 0)
        x0 = x;
      else
        x0 = Var.Vstack(x, M.Variable(m, Domain.GreaterThan(0.0)));

      Variable z = x0;

      for (int i = 0; i < l - 1; ++i)
      {
        Variable xi = M.Variable(pow2(l - i - 1), Domain.GreaterThan(0.0));
        for (int k = 0; k < pow2(l - i - 1); ++k)
          M.Constraint(Var.Vstack(z.Index(2 * k), z.Index(2 * k + 1), xi.Index(k)),
                       Domain.InRotatedQCone());
        z = xi;
      }

      Variable t0 = M.Variable(1, Domain.GreaterThan(0.0));
      M.Constraint(Var.Vstack(z, t0), Domain.InRotatedQCone());

      M.Constraint(Expr.Sub(Expr.Mul(System.Math.Pow(2, 0.5 * l), t), t0), Domain.EqualsTo(0.0));

      for (int i = pow2(l - m); i < pow2(l); ++i)
        M.Constraint(Expr.Sub(x0.Index(i), t), Domain.EqualsTo(0.0));
    }
    /**
        Purpose: Models the hypograph of the n-th power of the
        determinant of a positive definite matrix.

        The convex set (a hypograph)

          C = { (X, t) \in S^n_+ x R |  t <= det(X)^{1/n} },

        can be modeled as the intersection of a semidefinite cone

          [ X, Z; Z^T Diag(Z) ] >= 0

        and a number of rotated quadratic cones and affine hyperplanes,

          t <= (Z11*Z22*...*Znn)^{1/n}  (see geometric_mean).

        References:
        [1] "Lectures on Modern Optimization", Ben-Tal and Nemirovski, 2000.
     */
    public static void det_rootn(Model M, Variable X, Variable t)
    {
      int n = X.GetShape().Dim(0);

      // Setup variables
      Variable Y = M.Variable(Domain.InPSDCone(2 * n));

      // Setup Y = [X, Z; Z^T diag(Z)]
      Variable Y11 = Y.Slice(new int[] {0, 0}, new int[] {n, n});
      Variable Y21 = Y.Slice(new int[] {n, 0}, new int[] {2 * n, n});
      Variable Y22 = Y.Slice(new int[] {n, n}, new int[] {2 * n, 2 * n});

      M.Constraint( Expr.Sub(Expr.MulElm(Matrix.Eye(n), Y21), Y22), Domain.EqualsTo(0.0));
      M.Constraint( Expr.Sub(X, Y11), Domain.EqualsTo(0.0) );

      // t^n <= (Z11*Z22*...*Znn)
      Variable[] tmpv = new Variable[n];
      for (int i = 0; i < n; ++i) tmpv[i] = Y22.Index(i, i);
      Variable z = Var.Reshape(Var.Vstack(tmpv), n);
      geometric_mean(M, z, t);
    }

    public static double log2(int n)
    {
      return (System.Math.Log(n) / System.Math.Log(2));
    }
    public static int pow2(int n)
    {
      return (int) (1 << n);
    }

    public static Tuple<double[], double[]> lownerjohn_inner(double[][] A, double[] b)
    {
      using( Model M = new Model("lownerjohn_inner"))
      {
        int m = A.Length;
        int n = A[0].Length;

        // Setup variables
        Variable t = M.Variable("t", 1, Domain.GreaterThan(0.0));
        Variable C = M.Variable("C", new int[] {n, n}, Domain.Unbounded());
        Variable d = M.Variable("d", n, Domain.Unbounded());

        // (bi - ai^T*d, C*ai) \in Q
        for (int i = 0; i < m; ++i)
          M.Constraint("qc" + i, Expr.Vstack(Expr.Sub(b[i], Expr.Dot(A[i], d)), Expr.Mul(C, A[i])),
                       Domain.InQCone() );

        // t <= det(C)^{1/n}
        det_rootn(M, C, t);

        // Objective: Maximize t
        M.Objective(ObjectiveSense.Maximize, t);
        M.Solve();

        return Tuple.Create(C.Level(), d.Level());
      }
    }

    public static Tuple<double[], double[]> lownerjohn_outer(double[][] x)
    {
      using( Model M = new Model("lownerjohn_outer") )
      {
        int m = x.Length;
        int n = x[0].Length;

        // Setup variables
        Variable t = M.Variable("t", 1, Domain.GreaterThan(0.0));
        Variable P = M.Variable("P", new int[] {n, n}, Domain.Unbounded());
        Variable c = M.Variable("c", n, Domain.Unbounded());

        // (1, P(*xi+c)) \in Q
        for (int i = 0; i < m; ++i)
          M.Constraint("qc" + i, Expr.Vstack(Expr.Ones(1), Expr.Sub(Expr.Mul(P, x[i]), c)),
                       Domain.InQCone() );

        // t <= det(P)^{1/n}
        det_rootn(M, P, t);

        // Objective: Maximize t
        M.Objective(ObjectiveSense.Maximize, t);
        M.Solve();

        return Tuple.Create(P.Level(), c.Level());
      }
    }

    public static void Main(string[] argv)
    {
      double[][] p = new double[][] { new double[] {0.0, 0.0},
               new double[] {1.0, 3.0},
               new double[] {5.5, 4.5},
               new double[] {7.0, 4.0},
               new double[] {7.0, 1.0},
               new double[] {3.0, -2.0}
      };
      int n = p.Length;
      double[][] A = new double[n][];
      double[]   b = new double[n];
      for (int i = 0; i < n; ++i)
      {
        A[i] = new double[] { -p[i][1] + p[(i - 1 + n) % n][1], p[i][0] - p[(i - 1 + n) % n][0] };
        b[i] = A[i][0] * p[i][0] + A[i][1] * p[i][1];
      }

      Tuple<double[], double[]> ResInn = lownerjohn_inner(A, b);
      Tuple<double[], double[]> ResOut = lownerjohn_outer(p);
      double[] Ci = ResInn.Item1;
      double[] di = ResInn.Item2;
      double[] Po = ResOut.Item1;
      double[] co = ResOut.Item2;
      Console.WriteLine("Inner:");
      Console.WriteLine("  C = [{0}]", string.Join(", ", Ci));
      Console.WriteLine("  d = [{0}]", string.Join(", ", di));
      Console.WriteLine("Outer:");
      Console.WriteLine("  P = [{0}]", string.Join(", ", Po));
      Console.WriteLine("  c = [{0}]", string.Join(", ", co));
    }
  }
}

