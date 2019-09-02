/*
  File : portfolio.java

  Copyright : Copyright (c) MOSEK ApS, Denmark. All rights reserved.

  Description :
    Presents several portfolio optimization models.
*/
package com.mosek.fusion.examples;

import mosek.fusion.*;
import java.io.FileReader;
import java.io.BufferedReader;
import java.util.ArrayList;

public class portfolio {
  public static double sum(double[] x) {
    double r = 0.0;
    for (int i = 0; i < x.length; ++i) r += x[i];
    return r;
  }

  public static double dot(double[] x, double[] y) {
    double r = 0.0;
    for (int i = 0; i < x.length; ++i) r += x[i] * y[i];
    return r;
  }

  /*
  Purpose:
      Computes the optimal portfolio for a given risk

  Input:
      n: Number of assets
      mu: An n dimmensional vector of expected returns
      GT: A matrix with n columns so (GT')*GT  = covariance matrix
      x0: Initial holdings
      w: Initial cash holding
      gamma: Maximum risk (=std. dev) accepted

  Output:
      Optimal expected return and the optimal portfolio
  */
  public static double BasicMarkowitz
  ( int n,
    double[] mu,
    double[][] GT,
    double[] x0,
    double   w,
    double   gamma)
  throws mosek.fusion.SolutionError {

    Model M = new Model("Basic Markowitz");
    try {
      // Redirect log output from the solver to stdout for debugging.
      // if uncommented.
      //M.setLogHandler(new java.io.PrintWriter(System.out));

      // Defines the variables (holdings). Shortselling is not allowed.
      Variable x = M.variable("x", n, Domain.greaterThan(0.0));

      //  Maximize expected return
      M.objective("obj", ObjectiveSense.Maximize, Expr.dot(mu, x));

      // The amount invested  must be identical to intial wealth
      M.constraint("budget", Expr.sum(x), Domain.equalsTo(w + sum(x0)));

      // Imposes a bound on the risk
      M.constraint("risk", Expr.vstack(gamma, Expr.mul(GT, x)), Domain.inQCone());

      // Solves the model.
      M.solve();

      return dot(mu, x.level());
    } finally {
      M.dispose();
    }
  }

  /*
    Purpose:
        Computes several portfolios on the optimal portfolios by

            for alpha in alphas:
                maximize   expected return - alpha * standard deviation
                subject to the constraints

    Input:
        n: Number of assets
        mu: An n dimmensional vector of expected returns
        GT: A matrix with n columns so (GT')*GT  = covariance matrix
        x0: Initial holdings
        w: Initial cash holding
        alphas: List of the alphas

    Output:
        The efficient frontier as list of tuples (alpha,expected return,risk)
   */
  public static void EfficientFrontier
  ( int      n,
    double[] mu,
    double[][] GT,
    double[] x0,
    double   w,
    double[] alphas,

    double[]    frontier_mux,
    double[]    frontier_s)
  throws mosek.fusion.SolutionError {

    Model M = new Model("Efficient frontier");
    try {
      //M.setLogHandler(new java.io.PrintWriter(System.out));

      // Defines the variables (holdings). Shortselling is not allowed.
      Variable x = M.variable("x", n, Domain.greaterThan(0.0)); // Portfolio variables
      Variable s = M.variable("s", 1, Domain.unbounded()); // Risk variable

      M.constraint("budget", Expr.sum(x), Domain.equalsTo(w + sum(x0)));

      // Computes the risk
      M.constraint("risk", Expr.vstack(s, Expr.mul(GT, x)), Domain.inQCone());

      Expression mudotx = Expr.dot(mu, x);
      for (int i = 0; i < alphas.length; ++i) {
        //  Define objective as a weighted combination of return and risk
        M.objective("obj", ObjectiveSense.Maximize, Expr.sub( mudotx , Expr.mul(alphas[i], s)));

        M.solve();

        frontier_mux[i] = dot(mu, x.level());
        frontier_s[i]   = s.level()[0];
      }
    } finally {
      M.dispose();
    }
  }

  /*
      Description:
          Extends the basic Markowitz model with a market cost term.

      Input:
          n: Number of assets
          mu: An n dimmensional vector of expected returns
          GT: A matrix with n columns so (GT')*GT  = covariance matrix'
          x0: Initial holdings
          w: Initial cash holding
          gamma: Maximum risk (=std. dev) accepted
          m: It is assumed that  market impact cost for the j'th asset is
             m_j|x_j-x0_j|^3/2

      Output:
         Optimal expected return and the optimal portfolio

  */
  public static void MarkowitzWithMarketImpact
  ( int n,
    double[] mu,
    double[][] GT,
    double[] x0,
    double   w,
    double   gamma,
    double[] m,
    double[] xsol,
    double[] tsol)
  throws mosek.fusion.SolutionError {
    Model M = new Model("Markowitz portfolio with market impact");
    try {
      //M.setLogHandler(new java.io.PrintWriter(System.out));

      // Defines the variables. No shortselling is allowed.
      Variable x = M.variable("x", n, Domain.greaterThan(0.0));

      // Addtional "helper" variables
      Variable t = M.variable("t", n, Domain.unbounded());
      Variable z = M.variable("z", n, Domain.unbounded());
      Variable v = M.variable("v", n, Domain.unbounded());

      //  Maximize expected return
      M.objective("obj", ObjectiveSense.Maximize, Expr.dot(mu, x));

      // Invested amount + slippage cost = initial wealth
      M.constraint("budget", Expr.add(Expr.sum(x), Expr.dot(m, t)), Domain.equalsTo(w + sum(x0)));

      // Imposes a bound on the risk
      M.constraint("risk", Expr.vstack(gamma, Expr.mul(GT, x)),
                   Domain.inQCone());

      // z >= |x-x0|
      M.constraint("buy", Expr.sub(z, Expr.sub(x, x0)), Domain.greaterThan(0.0));
      M.constraint("sell", Expr.sub(z, Expr.sub(x0, x)), Domain.greaterThan(0.0));

      // t >= z^1.5, z >= 0.0. Needs two rotated quadratic cones to model this term
      M.constraint("ta", Var.hstack(v, t, z), Domain.inRotatedQCone());
      M.constraint("tb", Expr.hstack(z, Expr.constTerm(n, 1.0 / 8.0), v),
                   Domain.inRotatedQCone());

      M.solve();

      if (xsol != null)
        System.arraycopy(x.level(), 0, xsol, 0, n);
      if (tsol != null)
        System.arraycopy(t.level(), 0, tsol, 0, n);
    } finally {
      M.dispose();
    }
  }

  /*
      Description:
          Extends the basic Markowitz model with a market cost term.

      Input:
          n: Number of assets
          mu: An n dimmensional vector of expected returns
          GT: A matrix with n columns so (GT')*GT  = covariance matrix
          x0: Initial holdings
          w: Initial cash holding
          gamma: Maximum risk (=std. dev) accepted
          f: If asset j is traded then a fixed cost f_j must be paid
          g: If asset j is traded then a cost g_j must be paid for each unit traded

      Output:
         Optimal expected return and the optimal portfolio

  */
  public static double[] MarkowitzWithTransactionsCost
  ( int n,
    double[] mu,
    double[][] GT,
    double[] x0,
    double   w,
    double   gamma,
    double[] f,
    double[] g)
  throws mosek.fusion.SolutionError {

    // Upper bound on the traded amount
    double[] u = new double[n];
    {
      double v = w + sum(x0);
      for (int i = 0; i < n; ++i) u[i] = v;
    }

    Model M = new Model("Markowitz portfolio with transaction costs");
    try {
      //M.setLogHandler(new java.io.PrintWriter(System.out));

      // Defines the variables. No shortselling is allowed.
      Variable x = M.variable("x", n, Domain.greaterThan(0.0));

      // Addtional "helper" variables
      Variable z = M.variable("z", n, Domain.unbounded());
      // Binary varables
      Variable y = M.variable("y", n, Domain.binary());

      //  Maximize expected return
      M.objective("obj", ObjectiveSense.Maximize, Expr.dot(mu, x));

      // Invest amount + transactions costs = initial wealth
      M.constraint("budget", Expr.add(Expr.add(Expr.sum(x), Expr.dot(f, y)), Expr.dot(g, z)),
                   Domain.equalsTo(w + sum(x0)));

      // Imposes a bound on the risk
      M.constraint("risk", Expr.vstack( gamma, Expr.mul(GT, x)),
                   Domain.inQCone());

      // z >= |x-x0|
      M.constraint("buy", Expr.sub(z, Expr.sub(x, x0)), Domain.greaterThan(0.0));
      M.constraint("sell", Expr.sub(z, Expr.sub(x0, x)), Domain.greaterThan(0.0));

      //M.constraint("trade", Expr.hstack(z,Expr.sub(x,x0)), Domain.inQcone())"

      // Consraints for turning y off and on. z-diag(u)*y<=0 i.e. z_j <= u_j*y_j
      M.constraint("y_on_off", Expr.sub(z, Expr.mul(Matrix.diag(u), y)), Domain.lessThan(0.0));

      // Integer optimization problems can be very hard to solve so limiting the
      // maximum amount of time is a valuable safe guard
      M.setSolverParam("mioMaxTime", 180.0);
      M.solve();

      return x.level();
    } finally {
      M.dispose();
    }
  }


  /*
    The example. Reads in data and solves the portfolio models.
   */
  public static void main(String[] argv)
  throws java.io.IOException,
         java.io.FileNotFoundException,
         mosek.fusion.SolutionError {

    int        n      = 3;
    double     w      = 1.0;
    double[]   mu     = {0.1073, 0.0737, 0.0627};
    double[]   x0     = {0.0, 0.0, 0.0};
    double[]   gammas = {0.035, 0.040, 0.050, 0.060, 0.070, 0.080, 0.090};
    double[][] GT     = {
      { 0.166673333200005, 0.0232190712557243 ,  0.0012599496030238 },
      { 0.0              , 0.102863378954911  , -0.00222873156550421},
      { 0.0              , 0.0                ,  0.0338148677744977 }
    };


    System.out.println("\n\n================================");
    System.out.println("Markowitz portfolio optimization");
    System.out.println("================================\n");
    {
      System.out.println("\n-----------------------------------------------------------------------------------");
      System.out.println("Basic Markowitz portfolio optimization");
      System.out.println("-----------------------------------------------------------------------------------\n");
      for ( int i = 0; i < gammas.length; ++i) {
        double expret = BasicMarkowitz( n, mu, GT, x0, w, gammas[i]);
        System.out.format("Expected return: %.4e Std. deviation: %.4e\n",
                          expret,
                          gammas[i]);
      }
    }
    {
      // Some predefined alphas are chosen
      double[] alphas = { 0.0, 0.01, 0.1, 0.25, 0.30, 0.35, 0.4, 0.45, 0.5, 0.75, 1.0, 1.5, 2.0, 3.0, 10.0 };
      int      niter = alphas.length;
      double[] frontier_mux = new double[niter];
      double[] frontier_s   = new double[niter];

      EfficientFrontier(n, mu, GT, x0, w, alphas, frontier_mux, frontier_s);
      System.out.println("\n-----------------------------------------------------------------------------------");
      System.out.println("Efficient frontier") ;
      System.out.println("-----------------------------------------------------------------------------------\n");
      System.out.format("%-12s  %-12s  %-12s\n", "alpha", "return", "risk") ;
      for (int i = 0; i < frontier_mux.length; ++i)
        System.out.format("\t%-12.4f  %-12.4e  %-12.4e\n", alphas[i], frontier_mux[i], frontier_s[i]);
    }

    {
      // Somewhat arbirtrary choice of m
      double[] m = new double[n]; for (int i = 0; i < n; ++i) m[i] = 1.0e-2;
      double[] x = new double[n];
      double[] t = new double[n];

      MarkowitzWithMarketImpact(n, mu, GT, x0, w, gammas[0], m, x, t);
      System.out.println("\n-----------------------------------------------------------------------------------");
      System.out.println("Markowitz portfolio optimization with market impact cost");
      System.out.println("-----------------------------------------------------------------------------------\n");
      System.out.format("Expected return: %.4e Std. deviation: %.4e Market impact cost: %.4e\n",
                        dot(mu, x),
                        gammas[0],
                        dot(m, t));
    }

    {
      double[] f = new double[n]; java.util.Arrays.fill(f, 0.01);
      double[] g = new double[n]; java.util.Arrays.fill(g, 0.001);
      System.out.println("\n-----------------------------------------------------------------------------------");
      System.out.println("Markowitz portfolio optimization with transaction cost");
      System.out.println("-----------------------------------------------------------------------------------\n");

      double[] x = new double[n];
      x = MarkowitzWithTransactionsCost(n, mu, GT, x0, w, gammas[0], f, g);
      System.out.println("Optimal portfolio: \n");
      for ( int i = 0; i < x.length; ++i)
        System.out.format("\tx[%-2d]  %-12.4e\n", i, x[i]);
    }
  }
}