/*
  File : portfolio.cs

  Copyright : Copyright (c) MOSEK ApS, Denmark. All rights reserved.

  Description :
    Presents several portfolio optimization models.

  Note:
    This example uses LINQ, which is only available in .NET Framework 3.5 and later.
*/

using System.IO;
using System;
using System.Linq;
using System.Globalization;

namespace mosek.fusion.example
{
  public class portfolio
  {

    private static int        n      = 3;
    private static double     w      = 1.0;
    private static double[]   mu     = {0.1073, 0.0737, 0.0627};
    private static double[]   x0     = {0.0, 0.0, 0.0};
    private static double[]   gammas = {0.035, 0.040, 0.050, 0.060, 0.070, 0.080, 0.090};
    private static double[,] GT     = {
      { 0.166673333200005, 0.0232190712557243 ,  0.0012599496030238 },
      { 0.0              , 0.102863378954911  , -0.00222873156550421},
      { 0.0              , 0.0                ,  0.0338148677744977 }
    };
    public static double sum(double[] x)
    {
      double r = 0.0;
      for (int i = 0; i < x.Length; ++i) r += x[i];
      return r;
    }

    public static double dot(double[] x, double[] y)
    {
      double r = 0.0;
      for (int i = 0; i < x.Length; ++i) r += x[i] * y[i];
      return r;
    }

    /*
    Purpose:
        Computes the optimal portfolio for a given risk

    Input:
        n: Number of assets
        mu: An n dimmensional vector of expected returns
        GT: A matrix with n columns so (GT")*GT  = covariance matrix"
        x0: Initial holdings
        w: Initial cash holding
        gamma: Maximum risk (=std. dev) accepted

    Output:
        Optimal expected return and the optimal portfolio
    */
    public static double BasicMarkowitz
    ( int n,
      double[] mu,
      double[,]GT,
      double[] x0,
      double   w,
      double   gamma)
    {

      using( Model M = new Model("Basic Markowitz"))
      {

        // Redirect log output from the solver to stdout for debugging.
        // ifuncommented.
        //M.SetLogHandler(Console.Out);

        // Defines the variables (holdings). Shortselling is not allowed.
        Variable x = M.Variable("x", n, Domain.GreaterThan(0.0));

        //  Maximize expected return
        M.Objective("obj", ObjectiveSense.Maximize, Expr.Dot(mu, x));

        // The amount invested  must be identical to intial wealth
        M.Constraint("budget", Expr.Sum(x), Domain.EqualsTo(w + sum(x0)));
        // Imposes a bound on the risk
        M.Constraint("risk", Expr.Vstack(gamma, Expr.Mul(GT, x)), Domain.InQCone());
        // Solves the model.
        M.Solve();

        return dot(mu, x.Level());
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
          GT: A matrix with n columns so (GT")*GT  = covariance matrix"
          x0: Initial holdings
          w: Initial cash holding
          alphas: List of the alphas

      Output:
          The efficient frontier as list of tuples (alpha,expected return,risk)
     */
    public static void EfficientFrontier
    ( int n,
      double[]    mu,
      double [,]  GT,
      double[]    x0,
      double      w,
      double[]    alphas,
      double[]    frontier_mux,
      double[]    frontier_s)
    {
      using(Model M = new Model("Efficient frontier"))
      {
        //M.SetLogHandler(Console.Out);

        // Defines the variables (holdings). Shortselling is not allowed.
        Variable x = M.Variable("x", n, Domain.GreaterThan(0.0)); // Portfolio variables
        Variable s = M.Variable("s", 1, Domain.Unbounded()); // Risk variable

        M.Constraint("budget", Expr.Sum(x), Domain.EqualsTo(w + sum(x0)));

        // Computes the risk
        M.Constraint("risk", Expr.Vstack(s, Expr.Mul(GT, x)), Domain.InQCone());

        Expression mudotx = Expr.Dot(mu, x);

        for (int i = 0; i < alphas.Length; ++i)
        {
          //  Define objective as a weighted combination of return and risk
          M.Objective("obj", ObjectiveSense.Maximize, Expr.Sub(mudotx, Expr.Mul(alphas[i], s)));

          M.Solve();

          frontier_mux[i] = dot(mu, x.Level());
          frontier_s[i]   = s.Level()[0];
        }
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
      double[,]GT,
      double[] x0,
      double   w,
      double   gamma,
      double[] m,
      double[] xsol,
      double[] tsol)
    {
      using(Model M = new Model("Markowitz portfolio with market impact"))
      {

        //M.SetLogHandler(Console.Out);

        // Defines the variables. No shortselling is allowed.
        Variable x = M.Variable("x", n, Domain.GreaterThan(0.0));

        // Addtional "helper" variables
        Variable t = M.Variable("t", n, Domain.Unbounded());
        Variable z = M.Variable("z", n, Domain.Unbounded());
        Variable v = M.Variable("v", n, Domain.Unbounded());

        //  Maximize expected return
        M.Objective("obj", ObjectiveSense.Maximize, Expr.Dot(mu, x));

        // Invested amount + slippage cost = initial wealth
        M.Constraint("budget", Expr.Add(Expr.Sum(x), Expr.Dot(m, t)), Domain.EqualsTo(w + sum(x0)));

        // Imposes a bound on the risk
        M.Constraint("risk", Expr.Vstack(gamma, Expr.Mul(GT, x)), Domain.InQCone());

        // z >= |x-x0|
        M.Constraint("buy", Expr.Sub(z, Expr.Sub(x, x0)), Domain.GreaterThan(0.0));
        M.Constraint("sell", Expr.Sub(z, Expr.Sub(x0, x)), Domain.GreaterThan(0.0));

        // t >= z^1.5, z >= 0.0. Needs two rotated quadratic cones to model this term
        M.Constraint("ta", Expr.Hstack(v, t, z), Domain.InRotatedQCone());

        M.Constraint("tb", Expr.Hstack(z, Expr.ConstTerm(n, 1.0 / 8.0), v),
                     Domain.InRotatedQCone());
        M.Solve();

        if (xsol != null)
          Array.Copy(x.Level(), xsol, n);
        if (tsol != null)
          Array.Copy(t.Level(), tsol, n);
      }
    }

    /*
        Description:
            Extends the basic Markowitz model with a market cost term.

        Input:
            n: Number of assets
            mu: An n dimmensional vector of expected returns
            GT: A matrix with n columns so (GT")*GT  = covariance matrix"
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
      double[,]GT,
      double[] x0,
      double   w,
      double   gamma,
      double[] f,
      double[] g)
    {

      // Upper bound on the traded amount
      double[] u = new double[n];
      {
        double v = w + sum(x0);
        for (int i = 0; i < n; ++i) u[i] = v;
      }

      using( Model M = new Model("Markowitz portfolio with transaction costs") )
      {
        Console.WriteLine("\n-------------------------------------------------------------------------");
        Console.WriteLine("Markowitz portfolio optimization with transaction cost\n");
        Console.WriteLine("------------------------------------------------------------------------\n");

        //M.SetLogHandler(Console.Out);

        // Defines the variables. No shortselling is allowed.
        Variable x = M.Variable("x", n, Domain.GreaterThan(0.0));

        // Addtional "helper" variables
        Variable z = M.Variable("z", n, Domain.Unbounded());
        // Binary varables
        Variable y = M.Variable("y", n, Domain.Binary());

        //  Maximize expected return
        M.Objective("obj", ObjectiveSense.Maximize, Expr.Dot(mu, x));

        // Invest amount + transactions costs = initial wealth
        M.Constraint("budget", Expr.Add(Expr.Add(Expr.Sum(x), Expr.Dot(f, y)), Expr.Dot(g, z)),
                     Domain.EqualsTo(w + sum(x0)));

        // Imposes a bound on the risk
        M.Constraint("risk", Expr.Vstack(gamma, Expr.Mul(GT, x)), Domain.InQCone());

        // z >= |x-x0|
        M.Constraint("buy",  Expr.Sub(z, Expr.Sub(x, x0)), Domain.GreaterThan(0.0));
        M.Constraint("sell", Expr.Sub(z, Expr.Sub(x0, x)), Domain.GreaterThan(0.0));

        //M.constraint("trade", Expr.hstack(z,Expr.sub(x,x0)), Domain.inQcone())"

        // Consraints for turning y off and on. z-diag(u)*y<=0 i.e. z_j <= u_j*y_j
        M.Constraint("y_on_off", Expr.Sub(z, Expr.Mul(Matrix.Diag(u), y)), Domain.LessThan(0.0));

        // Integer optimization problems can be very hard to solve so limiting the
        // maximum amount of time is a valuable safe guard
        M.SetSolverParam("mioMaxTime", 180.0);
        M.Solve();
        Console.WriteLine("Expected return: {0:e4} Std. deviation: {1:e4} Transactions cost: {2:e4}",
                          dot(mu, x.Level()), gamma, dot(f, y.Level()) + dot(g, z.Level()));
        return x.Level();
      }
    }

    /*
      The example. Reads in data and solves the portfolio models.
     */
    public static void Main(string[] argv)
    {

      {
        Console.WriteLine("\n-------------------------------------------------------------------");
        Console.WriteLine("Basic Markowitz portfolio optimization");
        Console.WriteLine("---------------------------------------------------------------------\n");
        foreach (var gamma in gammas)
        {
          double res = BasicMarkowitz(n, mu, GT, x0, w, gamma);
          Console.WriteLine("Expected return: {0,-12:f4}  St deviation: {1,-12:f4} ", res, gamma);
        }
      }
      {
        // Some predefined alphas are chosen
        double[] alphas = { 0.0, 0.01, 0.1, 0.25, 0.30, 0.35, 0.4, 0.45, 0.5, 0.75, 1.0, 1.5, 2.0, 3.0, 10.0 };
        int      niter = alphas.Length;
        double[] frontier_mux = new double[niter];
        double[] frontier_s   = new double[niter];

        EfficientFrontier(n, mu, GT, x0, w, alphas, frontier_mux, frontier_s);
        Console.WriteLine("\n-------------------------------------------------------------------------");
        Console.WriteLine("Efficient frontier\n") ;
        Console.WriteLine("------------------------------------------------------------------------\n");
        Console.WriteLine("{0,-12}  {1,-12}  {2,-12}", "alpha", "return", "risk") ;
        for (int i = 0; i < frontier_mux.Length; ++i)
          Console.WriteLine("{0,-12:f4}  {1,-12:e4}  {2,-12:e4}", alphas[i], frontier_mux[i], frontier_s[i]);
      }

      {
        // Somewhat arbirtrary choice of m
        double[] m = new double[n]; for (int i = 0; i < n; ++i) m[i] = 1.0e-2;
        double[] x = new double[n];
        double[] t = new double[n];

        MarkowitzWithMarketImpact(n, mu, GT, x0, w, gammas[0], m, x, t);
        Console.WriteLine("\n-----------------------------------------------------------------------");
        Console.WriteLine("Markowitz portfolio optimization with market impact cost\n");
        Console.WriteLine("------------------------------------------------------------------------\n");
        Console.WriteLine("Expected return: {0:e4} St deviation: {1:e4} Market impact cost: {2:e4}\n",
                          dot(mu, x),
                          gammas[0],
                          dot(m, t));
      }

      {
        double[] f = new double[n]; for (var i = 0; i < n; ++i) f[i] = 0.01;
        double[] g = new double[n]; for (var i = 0; i < n; ++i) g[i] = 0.001;

        MarkowitzWithTransactionsCost(n, mu, GT, x0, w, gammas[0], f, g);
      }
    }
  }
}
