//
// Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.
//
// File:      TrafficNetworkModel.cs
//
// Purpose:   Demonstrates a traffix network problem as a conic quadratic problem.
//
// Source:    Robert Fourer, "Convexity Checking in Large-Scale Optimization",
//            OR 53 --- Nottingham 6-8 September 2011.
//
// The problem:
//            Given a directed graph representing a traffic network
//            with one source and one sink, we have for each arc an
//            associated capacity, base travel time and a
//            sensitivity. Travel time along a specific arc increases
//            as the flow approaches the capacity.
//
//            Given a fixed inflow we now wish to find the
//            configuration that minimizes the average travel time.


using System;
using mosek.fusion;

namespace mosek.fusion.example
{
  public class TrafficNetworkModel : Model
  {
    public class TrafficNetworkError : System.Exception
    {
      public TrafficNetworkError(string msg) : base(msg) {  }
    }

    private Variable flow;

    public TrafficNetworkModel
    ( int      numberOfNodes,
      int      source_idx,
      int      sink_idx,
      int[]    arc_i,
      int[]    arc_j,
      double[] arcSensitivity,
      double[] arcCapacity,
      double[] arcBaseTravelTime,
      double   T) : base("Traffic Network")

    {
      bool finished = false;
      try
      {
        int n = numberOfNodes;
        int narcs = arc_j.Length;

        double[] n_ones = new double[narcs]; for (int i = 0; i < narcs; ++i) n_ones[i] = 1.0;
        Set NxN = Set.Make(n, n);
        Matrix sens =
          Matrix.Sparse(n, n, arc_i, arc_j, arcSensitivity);
        Matrix cap =
          Matrix.Sparse(n, n, arc_i, arc_j, arcCapacity);
        Matrix basetime =
          Matrix.Sparse(n, n, arc_i, arc_j, arcBaseTravelTime);
        Matrix e =
          Matrix.Sparse(n, n, arc_i, arc_j, n_ones);
        Matrix e_e =
          Matrix.Sparse(n, n,
                        new int[]  { sink_idx}, new int[] { source_idx},
                        new double[] { 1.0 });

        double[] cs_inv = new double[narcs];
        double[] s_inv  = new double[narcs];
        for (int i = 0; i < narcs; ++i) cs_inv[i] = 1.0 / (arcSensitivity[i] * arcCapacity[i]);
        for (int i = 0; i < narcs; ++i) s_inv[i]  = 1.0 / arcSensitivity[i];
        Matrix cs_inv_matrix = Matrix.Sparse(n, n, arc_i, arc_j, cs_inv);
        Matrix s_inv_matrix  = Matrix.Sparse(n, n, arc_i, arc_j, s_inv);

        flow       = Variable("traffic_flow", NxN, Domain.GreaterThan(0.0));

        Variable x = flow;
        Variable t = Variable("travel_time",  NxN, Domain.GreaterThan(0.0));
        Variable d = Variable("d",            NxN, Domain.GreaterThan(0.0));
        Variable z = Variable("z",            NxN, Domain.GreaterThan(0.0));


        // Set the objective:
        Objective("Average travel time", ObjectiveSense.Minimize,
                  Expr.Mul(1.0 / T, Expr.Add(Expr.Dot(basetime, x), Expr.Dot(e, d))));

        // Set up constraints
        // Constraint (1a)
        {
          Variable[][] v = new Variable[narcs][];
          for (int i = 0; i < narcs; ++i)
          {
            v[i] = new Variable[3] { d.Index(arc_i[i], arc_j[i]),
                                     z.Index(arc_i[i], arc_j[i]),
                                     x.Index(arc_i[i], arc_j[i])
                                   };
          }
          Constraint("(1a)", mosek.fusion.Var.Stack(v), Domain.InRotatedQCone(narcs, 3));
        }

        // Constraint (1b)
        //
        Constraint("(1b)",
                   Expr.Sub(Expr.Add(Expr.MulElm(z, e),
                                     Expr.MulElm(x, cs_inv_matrix)),
                            s_inv_matrix),
                   Domain.EqualsTo(0.0));

        // Constraint (2)
        Constraint("(2)", Expr.Sub(Expr.Add(Expr.MulDiag(x, e.Transpose()),
                                            Expr.MulDiag(x, e_e.Transpose())),
                                   Expr.Add(Expr.MulDiag(x.Transpose(), e),
                                            Expr.MulDiag(x.Transpose(), e_e))),
                   Domain.EqualsTo(0.0));
        // Constraint (3)
        Constraint("(3)", x.Index(sink_idx, source_idx), Domain.EqualsTo(T));
        finished = true;
      }
      finally
      {
        if (!finished)
          Dispose();
      }
    }

    // Return the solution. We do this the easy and inefficeint way:
    // We fetch the whole NxN array og values, a lot of which are
    // zeros.
    public double[] getFlow()
    {
      return flow.Level();
    }

    public static void Main(string[] args)
    {
      int n             = 4;
      int[]    arc_i    = new int[]    {  0,    0,    2,    1,    2 };
      int[]    arc_j    = new int[]    {  1,    2,    1,    3,    3 };
      double[] arc_base = new double[] {  4.0,  1.0,  2.0,  1.0,  6.0 };
      double[] arc_cap  = new double[] { 10.0, 12.0, 20.0, 15.0, 10.0 };
      double[] arc_sens = new double[] {  0.1,  0.7,  0.9,  0.5,  0.1 };

      double   T          = 20.0;
      int      source_idx = 0;
      int      sink_idx   = 3;

      using (TrafficNetworkModel M =
               new TrafficNetworkModel(n, source_idx, sink_idx,
                                       arc_i, arc_j,
                                       arc_sens,
                                       arc_cap,
                                       arc_base,
                                       T))
      {
        M.WriteTask("TrafficNetworkModel.task");
        M.Solve();
        M.WriteTask("TrafficNetworkModel_solved.task");

        double[] flow = M.getFlow();

        System.Console.WriteLine("Optimal flow:");
        for (int i = 0; i < arc_i.Length; ++i)
          System.Console.WriteLine("\tflow node {0}->node {1} = {2}",
                                   arc_i[i], arc_j[i], flow[arc_i[i] * n + arc_j[i]]);
      }
    }
  }
}