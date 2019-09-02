//
//    Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.
//
//    File:    mioinitsol.cs
//
//    Purpose:  Demonstrates how to solve a small mixed
//             integer linear optimization problem
//             providing an initial feasible solution.
//
using System;
using mosek.fusion;

namespace mosek.fusion.example
{
  public class mioinitsol
  {
    public static void Main(string[] args)
    {
      double[] c = { 7.0, 10.0, 1.0, 5.0 };
      int n = 4;
      using (Model M = new Model("mioinitsol"))
      {

        Variable x = M.Variable("x", n, Domain.Integral(Domain.GreaterThan(0.0)));

        // Create the constraint
        M.Constraint(Expr.Sum(x), Domain.LessThan(2.5));

        // Set max solution time
        M.SetSolverParam("mioMaxTime", 60.0);
        // Set max relative gap (to its default value)
        M.SetSolverParam("mioTolRelGap", 1e-4);
        // Set max absolute gap (to its default value)
        M.SetSolverParam("mioTolAbsGap", 0.0);

        // Set the objective function to (c^T * x)
        M.Objective("obj", ObjectiveSense.Maximize, Expr.Dot(c, x));

        double[] init_sol = { 0.0, 2.0, 0.0, 0.0 };
        x.SetLevel( init_sol );

        // Solve the problem
        M.Solve();

        // Get the solution values
        double[] sol = x.Level();
        Console.Write("x = [");
        for(int i=0;i<n;i++)
        {
          Console.Write("{0}, ",sol[i]);
        }
        Console.WriteLine("]");
        double miorelgap = M.GetSolverDoubleInfo("mioObjRelGap");
        double mioabsgap = M.GetSolverDoubleInfo("mioObjAbsGap");
        Console.WriteLine("MIP rel gap = {0} ({0})", miorelgap, mioabsgap);
      }
    }
  }
}