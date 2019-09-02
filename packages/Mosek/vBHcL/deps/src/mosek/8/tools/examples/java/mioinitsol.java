/*
   Copyright : Copyright (c) MOSEK ApS, Denmark. All rights reserved.

   File :      mioinitsol.java

   Purpose :   Demonstrates how to solve a MIP with a start guess.

 */

package com.mosek.example;
import mosek.*;

class msgclass extends mosek.Stream {
  public msgclass () {
    super ();
  }

  public void stream (String msg) {
    System.out.print (msg);
  }
}

public class mioinitsol {
  public static void main (String[] args) {
    // Since the value infinity is never used, we define
    // 'infinity' symbolic purposes only
    double
    infinity = 0;

    int numvar = 4;
    int numcon = 1;

    double[] c = { 7.0, 10.0, 1.0, 5.0 };

    mosek.boundkey[] bkc = {mosek.boundkey.up};
    double[] blc = { -infinity};
    double[] buc = {2.5};
    mosek.boundkey[] bkx
    = {mosek.boundkey.lo,
       mosek.boundkey.lo,
       mosek.boundkey.lo,
       mosek.boundkey.lo
      };
    double[] blx = {0.0,
                    0.0,
                    0.0,
                    0.0
                   };
    double[] bux = {infinity,
                    infinity,
                    infinity,
                    infinity
                   };

    int[]    ptrb   = {0, 1, 2, 3};
    int[]    ptre   = {1, 2, 3, 4};
    double[] aval   = {1.0, 1.0, 1.0, 1.0};
    int[]    asub   = {0,   0,   0,   0  };
    int[]    intsub = {0, 1, 2};
    mosek.variabletype[] inttype = {mosek.variabletype.type_int,
                                    mosek.variabletype.type_int,
                                    mosek.variabletype.type_int
                                   };
    double[]    intxx = {0.0, 2, 0, 0, 0};

    try (Env  env  = new Env();
         Task task = new Task(env, 0, 0)) {
      // Directs the log task stream to the user specified
      // method task_msg_obj.print
      msgclass task_msg_obj = new msgclass ();
      task.set_Stream (mosek.streamtype.log, task_msg_obj);

      task.inputdata(numcon, numvar,
                     c, 0.0,
                     ptrb, ptre,
                     asub, aval,
                     bkc, blc, buc,
                     bkx, blx, bux);

      task.putvartypelist(intsub, inttype);

      /* A maximization problem */
      task.putobjsense(mosek.objsense.maximize);

      // Construct an initial feasible solution from the
      //     values of the integer valuse specified
      task.putintparam(mosek.iparam.mio_construct_sol,
                       mosek.onoffkey.on.value);

      // Assign values 0,2,0 to integer variables
      task.putxxslice(mosek.soltype.itg, 0, 3, intxx);
      
      // solve
      task.optimize();
    } catch (mosek.Exception e)
      /* Catch both Error and Warning */
    {
      System.out.println ("An error was encountered");
      System.out.println (e.getMessage ());
      throw e;
    }
  }
}