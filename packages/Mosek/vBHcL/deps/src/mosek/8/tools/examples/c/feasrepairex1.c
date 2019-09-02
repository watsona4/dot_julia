
/*
  Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.

  File:      feasrepairex1.c

  Purpose:   To demonstrate how to use the MSK_primalrepair function to
             repair an infeasible problem.

  Syntax: On command line
          feasrepairex1 feasrepair.lp
          feasrepair.lp is located in mosek\<version>\tools\examples\data\.
*/

#include <math.h>
#include <stdio.h>

#include "mosek.h"

static void MSKAPI printstr(void *handle,
                            const char str[])
{
  fputs(str, stdout);
} /* printstr */

int main(int argc, const char *argv[])
{
  const char  *filename = "../data/feasrepair.lp";
  MSKenv_t    env;
  MSKrescodee r;
  MSKtask_t   task;

  if ( argc > 1 )
    filename = argv[1];

  r = MSK_makeenv(&env, NULL);

  if ( r == MSK_RES_OK )
    r = MSK_makeemptytask(env, &task);

  if ( r == MSK_RES_OK )
    MSK_linkfunctotaskstream(task, MSK_STREAM_LOG, NULL, printstr);

  if ( r == MSK_RES_OK )
    r = MSK_readdata(task, filename); /* Read file from current dir */

  if ( r == MSK_RES_OK )
    r = MSK_putintparam(task, MSK_IPAR_LOG_FEAS_REPAIR, 3);

  if ( r == MSK_RES_OK )
  {
    /* Weights are NULL implying all weights are 1. */
    r = MSK_primalrepair(task, NULL, NULL, NULL, NULL);
  }

  if ( r == MSK_RES_OK )
  {
    double sum_viol;

    r = MSK_getdouinf(task, MSK_DINF_PRIMAL_REPAIR_PENALTY_OBJ, &sum_viol);

    if ( r == MSK_RES_OK )
    {
      printf("Minimized sum of violations = %e\n", sum_viol);

      r = MSK_optimize(task); /* Optimize the repaired task. */

      MSK_solutionsummary(task, MSK_STREAM_MSG);
    }
  }

  printf("Return code: %d\n", r);

  return ( r );
}