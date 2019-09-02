//
// Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.
//
// File:      TrafficNetworkModel.java
//
// Purpose:   Demonstrates a traffic network problem as a conic quadratic problem.
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

package com.mosek.fusion.examples;
import mosek.fusion.*;

public class TrafficNetworkModel extends Model {
  public class TrafficNetworkError extends Exception {
    public TrafficNetworkError(String msg) { super(msg); }
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
    double   T) {
    super("Traffic Network");
    
    boolean finished = false;
    try {
      int n = numberOfNodes;
      int narcs = arc_j.length;

      double[] n_ones = new double[narcs]; for (int i = 0; i < narcs; ++i) n_ones[i] = 1.0;
      Set NxN = Set.make(n, n);
      Matrix sens =
        Matrix.sparse(n, n, arc_i, arc_j, arcSensitivity);
      Matrix cap =
        Matrix.sparse(n, n, arc_i, arc_j, arcCapacity);
      Matrix basetime =
        Matrix.sparse(n, n, arc_i, arc_j, arcBaseTravelTime);
      Matrix e =
        Matrix.sparse(n, n, arc_i, arc_j, n_ones);
      Matrix e_e =
        Matrix.sparse(n, n,
                      new int[]  { sink_idx}, new int[] { source_idx},
                      new double[] { 1.0 });

      double[] cs_inv = new double[narcs];
      double[] s_inv  = new double[narcs];
      for (int i = 0; i < narcs; ++i) cs_inv[i] = 1.0 / (arcSensitivity[i] * arcCapacity[i]);
      for (int i = 0; i < narcs; ++i) s_inv[i]  = 1.0 / arcSensitivity[i];
      Matrix cs_inv_matrix = Matrix.sparse(n, n, arc_i, arc_j, cs_inv);
      Matrix s_inv_matrix  = Matrix.sparse(n, n, arc_i, arc_j, s_inv);

      flow       = variable("traffic_flow", NxN, Domain.greaterThan(0.0));

      Variable x = flow;
      Variable t = variable("travel_time" , NxN, Domain.greaterThan(0.0));
      Variable d = variable("d",            NxN, Domain.greaterThan(0.0));
      Variable z = variable("z",            NxN, Domain.greaterThan(0.0));


      // Set the objective:
      objective("Average travel time",
                ObjectiveSense.Minimize,
                Expr.mul(1.0 / T, Expr.add(Expr.dot(basetime, x), Expr.dot(e, d))));

      // Set up constraints
      // Constraint (1a)
      {
        Variable[][] v = new Variable[narcs][3];
        for (int i = 0; i < narcs; ++i) {
          v[i][0] = d.index(arc_i[i], arc_j[i]);
          v[i][1] = z.index(arc_i[i], arc_j[i]);
          v[i][2] = x.index(arc_i[i], arc_j[i]);
        }
        constraint("(1a)",
                   Var.stack(v), Domain.inRotatedQCone(narcs, 3));
      }

      // Constraint (1b)
      constraint("(1b)",
                 Expr.sub(Expr.add(Expr.mulElm(z, e),
                                   Expr.mulElm(x, cs_inv_matrix)),
                          s_inv_matrix),
                 Domain.equalsTo(0.0));

      // Constraint (2)
      constraint("(2)",
                 Expr.sub(Expr.add(Expr.mulDiag(x, e.transpose()),
                                   Expr.mulDiag(x, e_e.transpose())),
                          Expr.add(Expr.mulDiag(x.transpose(), e),
                                   Expr.mulDiag(x.transpose(), e_e))),
                 Domain.equalsTo(0.0));
      // Constraint (3)
      constraint("(3)",
                 x.index(sink_idx, source_idx), Domain.equalsTo(T));
      finished = true;
    } finally {
      if (! finished) {
        dispose();
      }
    }
  }

  // Return the solution. We do this the easy and inefficeint way:
  // We fetch the whole NxN array og values, a lot of which are
  // zeros.
  public double[] getFlow()
  throws SolutionError {
    return flow.level();
  }

  public static void main(String[] args)
  throws SolutionError {
    int n             = 4;
    int[]    arc_i    = new int[]    {  0,    0,    2,    1,    2 };
    int[]    arc_j    = new int[]    {  1,    2,    1,    3,    3 };
    double[] arc_base = new double[] {  4.0,  1.0,  2.0,  1.0,  6.0 };
    double[] arc_cap  = new double[] { 10.0, 12.0, 20.0, 15.0, 10.0 };
    double[] arc_sens = new double[] {  0.1,  0.7,  0.9,  0.5,  0.1 };

    double   T          = 20.0;
    int      source_idx = 0;
    int      sink_idx   = 3;

    TrafficNetworkModel M =
      new TrafficNetworkModel(n, source_idx, sink_idx,
                              arc_i, arc_j,
                              arc_sens,
                              arc_cap,
                              arc_base,
                              T);
    try {
      M.writeTask("trafficnetwork.opf");
      M.solve();

      double[] flow = M.getFlow();

      System.out.println("Optimal flow:");
      for (int i = 0; i < arc_i.length; ++i)
        System.out.println("\tflow node" + arc_i[i] + "->node" + arc_j[i] + " = " + flow[arc_i[i] * n + arc_j[i]]);
    } finally {
      M.dispose();
    }
  }
}