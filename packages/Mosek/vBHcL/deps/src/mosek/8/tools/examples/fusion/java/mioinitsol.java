//
//    Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.
//
//    File:    mioinitsol.java
//
//    Purpose:  Demonstrates how to solve a small mixed
//              integer linear optimization problem.
//
package com.mosek.fusion.examples;
import mosek.fusion.*;

public class mioinitsol {
  public static void main(String[] args)
  throws SolutionError {
    int n = 4;
    double[] c = { 7.0, 10.0, 1.0, 5.0 };

    Model M = new Model("mioinitsol");
    try {
      Variable x = M.variable("x", n, Domain.integral(Domain.greaterThan(0.0)));

      M.constraint(Expr.sum(x), Domain.lessThan(2.5));

      M.setSolverParam("mioMaxTime", 60.0);
      M.setSolverParam("mioTolRelGap", 1e-4);
      M.setSolverParam("mioTolAbsGap", 0.0);

      M.objective("obj", ObjectiveSense.Maximize, Expr.dot(c, x));

      double[] init_sol = { 0.0, 2.0, 0.0, 0.0 };      
      x.setLevel( init_sol );

      M.solve();

      // Get the solution values
      double[] sol = x.level();
      System.out.printf("x = [");
      for (int i = 0; i < n; i++) {
        System.out.printf("%e, ", sol[i]);
      }
      System.out.printf("]\n");
      System.out.printf("MIP rel gap = %.2f (%f)",
                        M.getSolverDoubleInfo("mioObjRelGap"),
                        M.getSolverDoubleInfo("mioObjAbsGap"));
    } finally {
      M.dispose();
    }
  }
}