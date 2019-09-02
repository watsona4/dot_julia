/*
   Copyright : Copyright (c) MOSEK ApS, Denmark. All rights reserved.

   File :      scopt1.java

   Purpose :   Demonstrates how to solve a simple non-linear separable problem
               using the SCopt interface for Java. The problem is:

               Minimize   e^x1 - ln(x0)
               Such that  x1 ln(x1) <= 0
                          x0^1/2 - x1 >= 0
                          1/2 <= x0, x1 <= 1
*/

package com.mosek.example;
import mosek.*;

public class scopt1 {
  public static void main(String[] args) {
    try (Env  env  = new Env();
         Task task = new Task(env, 0, 0)) {
      task.set_Stream(
        mosek.streamtype.log,
        new mosek.Stream()
      { public void stream(String msg) { System.out.print(msg); }});

      int numvar = 2;
      int numcon = 2;
      double inf = 0.;

      mosek.boundkey[]
      bkc = new mosek.boundkey[] {
        mosek.boundkey.up,
        mosek.boundkey.lo
      };

      double[] blc = new double[] { -inf, .0 };
      double[] buc = new double[] {  .0, inf};

      mosek.boundkey[] bkx = new mosek.boundkey[] {
        mosek.boundkey.ra, mosek.boundkey.ra
      };

      double[] blx = new double[] {0.5, 0.5};
      double[] bux = new double[] {1.0, 1.0};

      task.appendvars(numvar);
      task.appendcons(numcon);

      task.putvarboundslice(0, numvar, bkx, blx, bux);
      task.putconboundslice(0, numcon, bkc, blc, buc);

      task.putaij(1, 1, -1.0);

      mosek.scopr[] opro  = new mosek.scopr[] {mosek.scopr.log, mosek.scopr.exp};
      int[]    oprjo      = new int[]    {    0,   1 };
      double[] oprfo      = new double[] { -1.0, 1.0 };
      double[] oprgo      = new double[] {  1.0, 1.0 };
      double[] oprho      = new double[] {  0.0, 0.0 };


      mosek.scopr[] oprc  = new mosek.scopr[] { mosek.scopr.ent, mosek.scopr.pow };
      int[] opric         = new int[]    {   0,   1 };
      int[] oprjc         = new int[]    {   1,   0 };
      double[] oprfc      = new double[] { 1.0, 1.0 };
      double[] oprgc      = new double[] {  .0, 0.5 };
      double[] oprhc      = new double[] {  .0, 0.0 };

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

      System.out.print("Solution is: [ " + res[0]);
      for (int i = 1; i < numvar; ++i) System.out.print(", " + res[i]);
      System.out.println(" ]");
    } catch (mosek.Exception e) {
      System.out.println ("An error/warning was encountered");
      System.out.println (e.toString());
      throw e;
    }
  }
}