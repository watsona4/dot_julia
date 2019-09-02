/* 
   Copyright : Copyright (c) MOSEK ApS, Denmark. All rights reserved.

   File :      MatlabCallback.java

   Purpose :   An implementation of a callback function in Java
*/
package com.mosek.fusion.examples;

import mosek.*;
import mosek.fusion.*;
import java.util.*;
import java.lang.*;  

public class MatlabCallback extends mosek.DataCallback
{
  
  private double maxtime;
  private Model M;

  public MatlabCallback(Model M_, double maxtime_) {
    M = M_;
    maxtime = maxtime_;
  }

  public int callback(callbackcode caller,
                      double[]     douinf,
                      int[]        intinf,
                      long[]       lintinf)
  {

    double opttime = 0.0;
    int itrn;
    double pobj, dobj, stime;

    Formatter f = new Formatter(System.out);
    switch (caller)
    {
      case begin_intpnt:
          f.format("Starting interior-point optimizer\n");
          break;
      case intpnt:
          itrn    = intinf[iinfitem.intpnt_iter.value      ];
          pobj    = douinf[dinfitem.intpnt_primal_obj.value];
          dobj    = douinf[dinfitem.intpnt_dual_obj.value  ];
          stime   = douinf[dinfitem.intpnt_time.value      ];
          opttime = douinf[dinfitem.optimizer_time.value   ];

          f.format("Iterations: %-3d\n",itrn);
          f.format("  Elapsed time: %6.2f(%.2f)\n",opttime,stime);
          f.format("  Primal obj.: %-18.6e  Dual obj.: %-18.6e\n",pobj,dobj);
          break;
      case end_intpnt:
          f.format("Interior-point optimizer finished.\n");
          break;
      case begin_primal_simplex:
          f.format("Primal simplex optimizer started.\n");
          break;
      case update_primal_simplex:
          itrn    = intinf[iinfitem.sim_primal_iter.value  ];
          pobj    = douinf[dinfitem.sim_obj.value          ];
          stime   = douinf[dinfitem.sim_time.value         ];
          opttime = douinf[dinfitem.optimizer_time.value   ];
    
          f.format("Iterations: %-3d\n", itrn);
          f.format("  Elapsed time: %6.2f(%.2f)\n",opttime,stime);
          f.format("  Obj.: %-18.6e\n", pobj );
          break;
      case end_primal_simplex:
          f.format("Primal simplex optimizer finished.\n");
          break;
      case begin_dual_simplex:
          f.format("Dual simplex optimizer started.\n");
          break;
      case update_dual_simplex:
          itrn    = intinf[iinfitem.sim_dual_iter.value    ];
          pobj    = douinf[dinfitem.sim_obj.value          ];
          stime   = douinf[dinfitem.sim_time.value         ];
          opttime = douinf[dinfitem.optimizer_time.value   ];
          f.format("Iterations: %-3d\n", itrn);
          f.format("  Elapsed time: %6.2f(%.2f)\n",opttime,stime);
          f.format("  Obj.: %-18.6e\n", pobj);
          break;
      case end_dual_simplex:
          f.format("Dual simplex optimizer finished.\n");
          break;
      case begin_bi:
          f.format("Basis identification started.\n");
          break;
      case end_bi:
          f.format("Basis identification finished.\n");
          break;
      default:
    }
    System.out.flush();
    if (opttime >= maxtime)
    {
      f.format("MOSEK is spending too much time. Terminate it.\n");
      System.out.flush();
      return 1;
    }
    return 0;
  }
}