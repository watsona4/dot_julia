/*
  Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.

  File:    scopt1.cs

  Purpose: Demonstrates how to solve a simple non-liner separable problem
           using the SCopt interface for .NET. Then problem is this:

           Minimize  e^x1 - ln(x0)
           Such that  x1 ln(x1)   <= 0
                      x0^1/2 - x1 >= 0
                      1/2 x0, x1 <= 1

*/

using System;

namespace mosek.example
{
  class msgclass : mosek.Stream
  {
    string prefix;
    public msgclass (string prfx)
    {
      prefix = prfx;
    }

    public override void streamCB (string msg)
    {
      Console.Write ("{0}{1}", prefix, msg);
    }
  }

  public class scopt01
  {
    public static void Main ()
    {
      // Make mosek environment.
      using (mosek.Env env = new mosek.Env())
      {
        // Create a task object.
        using (mosek.Task task = new mosek.Task(env, 0, 0))
        {
          // Directs the log task stream to the user specified
          // method msgclass.streamCB
          task.set_Stream (mosek.streamtype.log, new msgclass (""));

          int numvar = 2;
          int numcon = 2;
          double inf = 0.0;

          mosek.boundkey[] bkc = {mosek.boundkey.up, mosek.boundkey.lo};

          double[] blc = { -inf, 0.0};
          double[] buc = {0.0 , inf};

          mosek.boundkey[] bkx = {mosek.boundkey.ra, mosek.boundkey.ra};

          double[] blx = {0.5, 0.5};
          double[] bux = {1.0, 1.0};

          task.appendvars(numvar);
          task.appendcons(numcon);

          task.putvarboundslice(0, numvar, bkx, blx, bux);
          task.putconboundslice(0, numcon, bkc, blc, buc);

          task.putaij(1, 1, -1.0);

          mosek.scopr[] opro  = {mosek.scopr.log, mosek.scopr.exp};
          int[]         oprjo = {              0,               1};
          double[]      oprfo = {           -1.0,             1.0};
          double[]      oprgo = {            1.0,             1.0};
          double[]      oprho = {            0.0,             0.0};


          mosek.scopr[] oprc  = new mosek.scopr[] { mosek.scopr.ent, mosek.scopr.pow };
          int[]         opric =                   {               0,               1 };
          int[]         oprjc =                   {               1,               0 };
          double[]      oprfc =                   {             1.0,             1.0 };
          double[]      oprgc =                   {              .0,             0.5 };
          double[]      oprhc =                   {              .0,             0.0 };

          task.putSCeval(opro, oprjo, oprfo, oprgo, oprho,
                         oprc, opric, oprjc, oprfc, oprgc, oprhc);

          task.putintparam(mosek.iparam.write_ignore_incompatible_items, 1);
          task.writeSC("scopt1.sco", "scopt1.opf");

          task.optimize();

          double[] res = new double[numvar];
          task.getsolutionslice(
            mosek.soltype.itr,
            mosek.solitem.xx,
            0, numvar,
            res);

          for (int j = 0; j < numvar; ++j)
            Console.WriteLine ("x[{0}]: {1}", j, res[j]);

        }
      }
    }
  }
}