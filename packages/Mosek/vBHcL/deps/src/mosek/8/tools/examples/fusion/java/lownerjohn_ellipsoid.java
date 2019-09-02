package com.mosek.fusion.examples;
/**
  Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.

  File:      lownerjohn_ellipsoid.java

  Purpose:
  Computes the Lowner-John inner and outer ellipsoidal
  approximations of a polytope.

  References:
    [1] "Lectures on Modern Optimization", Ben-Tal and Nemirovski, 2000.
    [2] "MOSEK modeling manual", 2013
*/

import java.util.Arrays;
import mosek.fusion.*;

public class lownerjohn_ellipsoid {
  /**
    Models the convex set

      S = { (x, t) \in R^n x R | x >= 0, t <= (x1 * x2 * ... * xn)^(1/n) }

    as  the intersection of rotated quadratic cones and affine hyperplanes.
    see [1, p. 105] or [2, p. 21].  This set can be interpreted as the hypograph of the
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
  */
  public static void geometric_mean(Model M, Variable x, Variable t) {
    int n = (int) x.size();
    int l = (int)Math.ceil(Math.log(n) / Math.log(2));
    int m = pow2(l) - n;

    Variable x0;

    if (m == 0)
      x0 = x;
    else
      x0 = Var.vstack(x, M.variable(m, Domain.greaterThan(0.0)));

    Variable z = x0;

    for (int i = 0; i < l - 1; ++i) {
      Variable xi = M.variable(pow2(l - i - 1), Domain.greaterThan(0.0));
      for (int k = 0; k < pow2(l - i - 1); ++k)
        M.constraint(Var.vstack(z.index(2 * k), z.index(2 * k + 1), xi.index(k)),
                     Domain.inRotatedQCone());
      z = xi;
    }

    Variable t0 = M.variable(1, Domain.greaterThan(0.0));
    M.constraint(Var.vstack(z, t0), Domain.inRotatedQCone());

    M.constraint(Expr.sub(Expr.mul(Math.pow(2, 0.5 * l), t), t0), Domain.equalsTo(0.0));

    for (int i = pow2(l - m); i < pow2(l); ++i)
      M.constraint(Expr.sub(x0.index(i), t), Domain.equalsTo(0.0));
  }

  /**
   Purpose: Models the hypograph of the n-th power of the
   determinant of a positive definite matrix. See [1,2] for more details.

   The convex set (a hypograph)

   C = { (X, t) \in S^n_+ x R |  t <= det(X)^{1/n} },

   can be modeled as the intersection of a semidefinite cone

   [ X, Z; Z^T Diag(Z) ] >= 0

   and a number of rotated quadratic cones and affine hyperplanes,

   t <= (Z11*Z22*...*Znn)^{1/n}  (see geometric_mean).
   */
  public static void det_rootn(Model M, Variable X, Variable t) {
    int n = X.getShape().dim(0);

    // Setup variables
    Variable Y = M.variable(Domain.inPSDCone(2 * n));

    // Setup Y = [X, Z; Z^T diag(Z)]
    Variable Y11 = Y.slice(new int[] {0, 0}, new int[] {n,   n});
    Variable Y21 = Y.slice(new int[] {n, 0}, new int[] {2 * n, n});
    Variable Y22 = Y.slice(new int[] {n, n}, new int[] {2 * n, 2 * n});

    M.constraint( Expr.sub(Y21.diag(), Y22.diag()), Domain.equalsTo(0.0) );
    M.constraint( Expr.sub(X, Y11), Domain.equalsTo(0.0) );

    // t^n <= (Z11*Z22*...*Znn)
    geometric_mean(M, Y22.diag(), t);
  }


  public static int pow2(int n) {
    return (int) (1 << n);
  }

  /**
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
  */
  public static Object[] lownerjohn_inner(double[][] A, double[] b)
  throws SolutionError {
    Model M = new Model("lownerjohn_inner");
    try {
      int m = A.length;
      int n = A[0].length;

      //Setup variables
      Variable t = M.variable("t", 1, Domain.greaterThan(0.0));
      Variable C = M.variable("C", Domain.inPSDCone(n));
      Variable d = M.variable("d", n, Domain.unbounded());

      // (b-Ad, AC) generate cones
      M.constraint("qc", Expr.hstack(Expr.sub(b, Expr.mul(A, d)), Expr.mul(A, C)),
                   Domain.inQCone());
      //t <= det(C)^{1/n}
      det_rootn(M, C, t);

      // Objective: Maximize t
      M.objective(ObjectiveSense.Maximize, t);
      M.solve();

      return new Object[] {C.level(), d.level()};
    } finally {
      M.dispose();
    }
  }

  /**
  The outer ellipsoidal approximation to a polytope given
  as the convex hull of a set of points

    S = conv{ x1, x2, ... , xm }

  minimizes the volume of the enclosing ellipsoid,

    { x | || P*x-c ||_2 <= 1 }

  The volume is proportional to det(P)^{-1/n}, so the problem can
  be solved as

    maximize         t
    subject to       t       <= det(P)^(1/n)
                || P*xi - c ||_2 <= 1,  i=1,...,m
                P is PSD.
  */
  public static Object[] lownerjohn_outer(double[][] x)
  throws SolutionError {
    Model M = new Model("lownerjohn_outer");
    try {
      int m = x.length;
      int n = x[0].length;

      //Setup variables
      Variable t = M.variable("t", 1, Domain.greaterThan(0.0));
      Variable P = M.variable("P", Domain.inPSDCone(n));
      Variable c = M.variable("c", n, Domain.unbounded());

      //(1, Px-c) in cone
      M.constraint("qc",
                   Expr.hstack(Expr.ones(m),
                               Expr.sub(Expr.mul(x, P),
                                        Var.reshape(Var.repeat(c, m), new int[] {m, n})
                                       )
                              ),
                   Domain.inQCone());

      //t <= det(P)^{1/n}
      det_rootn(M, P, t);

      //Objective: Maximize t
      M.objective(ObjectiveSense.Maximize, t);
      M.solve();

      return new Object[] {P.level(), c.level()};
    } finally {
      M.dispose();
    }
  }

  /**************************************************************************************/
  public static void main(String[] argv)
  throws SolutionError {
    //The list of vertices of a polygon
    final double[][] p = { {0., 0.}, {1., 3.}, {5.5, 4.5}, {7., 4.}, {7., 1.}, {3., -2.}  };
    double[][] A = new double[p.length][];
    double[]   b = new double[p.length];
    int n = p.length;

    //The h-representation of that polygon
    for (int i = 0; i < n; ++i) {
      A[i] = new double[] { -p[i][1] + p[(i - 1 + n) % n][1], p[i][0] - p[(i - 1 + n) % n][0] };
      b[i] = A[i][0] * p[i][0] + A[i][1] * p[i][1];
    }

    Object[] ResInn = lownerjohn_inner(A, b);
    Object[] ResOut = lownerjohn_outer(p);
    double[] Ci = (double[]) ResInn[0];
    double[] di = (double[]) ResInn[1];
    double[] Po = (double[]) ResOut[0];
    double[] co = (double[]) ResOut[1];
    System.out.println("Inner:");
    System.out.println("  C = " + Arrays.toString(Ci));
    System.out.println("  d = " + Arrays.toString(di));
    System.out.println("Outer:");
    System.out.println("  P = " + Arrays.toString(Po));
    System.out.println("  c = " + Arrays.toString(co));
  }
}