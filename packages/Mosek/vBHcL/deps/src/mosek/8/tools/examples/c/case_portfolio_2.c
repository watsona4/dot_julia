/*
  File : case_portfolio_2.c

  Copyright : Copyright (c) MOSEK ApS, Denmark. All rights reserved.

  Description :  Implements a basic portfolio optimization model.
 */
#include <math.h>
#include <stdio.h>

#include "mosek.h"

#define MOSEKCALL(_r,_call)  if ( (_r)==MSK_RES_OK ) (_r) = (_call)

static void MSKAPI printstr(void *handle,
                            const char str[])
{
  printf("%s", str);
} /* printstr */

int main(int argc, const char **argv)
{
  char            buf[128];
  const MSKint32t n          = 3,
                  numalpha   = 12;
  const double    mu[]       = {0.1073,  0.0737,  0.0627},
                  x0[3]      = {0.0, 0.0, 0.0},
                  w          = 1.0,
                  alphas[12] = {0.0, 0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5},
                  GT[][3]    = {{0.1667,  0.0232,  0.0013},
                                {0.0000,  0.1033, -0.0022},
                                {0.0000,  0.0000,  0.0338}};
  double          expret,
                  stddev,
                  alpha;
  MSKenv_t        env;
  MSKint32t       k, i, j, offsetx, offsets, offsett;
  MSKrescodee     res = MSK_RES_OK;
  MSKtask_t       task;
  MSKrealt        xj;
  MSKsolstae      solsta;

  /* Initial setup. */
  env  = NULL;
  task = NULL;
  MOSEKCALL(res, MSK_makeenv(&env, NULL));
  MOSEKCALL(res, MSK_maketask(env, 0, 0, &task));
  MOSEKCALL(res, MSK_linkfunctotaskstream(task, MSK_STREAM_LOG, NULL, printstr));

  /* Constraints. */
  MOSEKCALL(res, MSK_appendcons(task, 1 + n));
  MOSEKCALL(res, MSK_putconbound(task, 0, MSK_BK_FX, 1.0, 1.0));
  sprintf(buf, "%s", "budget");
  MOSEKCALL(res, MSK_putconname(task, 0, buf));

  for (i = 0; i < n; ++i)
  {
    MOSEKCALL(res, MSK_putconbound(task, 1 + i, MSK_BK_FX, 0.0, 0.0));
    sprintf(buf, "GT[%d]", 1 + i);
    MOSEKCALL(res, MSK_putconname(task, 1 + i, buf));
  }

  /* Variables. */
  MOSEKCALL(res, MSK_appendvars(task, 1 + 2 * n));

  offsetx = 0;   /* Offset of variable x into the API variable. */
  offsets = n;   /* Offset of variable x into the API variable. */
  offsett = n + 1; /* Offset of variable t into the API variable. */

  /* x variables. */
  for (j = 0; j < n; ++j)
  {
    MOSEKCALL(res, MSK_putcj(task, offsetx + j, mu[j]));
    MOSEKCALL(res, MSK_putaij(task, 0, offsetx + j, 1.0));
    for (k = 0; k < n; ++k)
      if ( GT[k][j] != 0.0 )
        MOSEKCALL(res, MSK_putaij(task, 1 + k, offsetx + j, GT[k][j]));

    MOSEKCALL(res, MSK_putvarbound(task, offsetx + j, MSK_BK_LO, 0.0, MSK_INFINITY));
    sprintf(buf, "x[%d]", 1 + j);
    MOSEKCALL(res, MSK_putvarname(task, offsetx + j, buf));
  }

  /* s variable. */
  MOSEKCALL(res, MSK_putvarbound(task, offsets + 0, MSK_BK_FR, -MSK_INFINITY, MSK_INFINITY));
  sprintf(buf, "s");
  MOSEKCALL(res, MSK_putvarname(task, offsets + 0, buf));

  /* t variables. */
  for (j = 0; j < n; ++j)
  {
    MOSEKCALL(res, MSK_putaij(task, 1 + j, offsett + j, -1.0));
    MOSEKCALL(res, MSK_putvarbound(task, offsett + j, MSK_BK_FR, -MSK_INFINITY, MSK_INFINITY));
    sprintf(buf, "t[%d]", 1 + j);
    MOSEKCALL(res, MSK_putvarname(task, offsett + j, buf));
  }

  if ( res == MSK_RES_OK )
  {
    /* sub should be n+1 long i.e. the dimmension of the cone. */
    MSKint32t *sub = (MSKint32t *) MSK_calloctask(task, n + 1, sizeof(MSKint32t));

    if ( sub )
    {
      sub[0] = offsets + 0;
      for (j = 0; j < n; ++j)
        sub[j + 1] = offsett + j;

      MOSEKCALL(res, MSK_appendcone(task, MSK_CT_QUAD, 0.0, n + 1, sub));
      MOSEKCALL(res, MSK_putconename(task, 0, "stddev"));

      MSK_freetask(task, sub);
    }
    else
      res = MSK_RES_ERR_SPACE;
  }

  MOSEKCALL(res, MSK_putobjsense(task, MSK_OBJECTIVE_SENSE_MAXIMIZE));

  /* Turn all log output off. */
  MOSEKCALL(res, MSK_putintparam(task, MSK_IPAR_LOG, 0));

  printf("%-12s  %-12s  %-12s\n", "alpha", "exp ret", "std dev");

  for (k = 0; k < numalpha; ++k)
  {
    alpha = alphas[k];

    /* Sets the objective function coefficient for s. */
    MOSEKCALL(res, MSK_putcj(task, offsets + 0, -alpha));

    MOSEKCALL(res, MSK_optimize(task));

    MOSEKCALL(res, MSK_getsolsta(task, MSK_SOL_ITR, &solsta));

    if ( solsta == MSK_SOL_STA_OPTIMAL || solsta == MSK_SOL_STA_NEAR_OPTIMAL )
    {
      expret = 0.0;
      for (j = 0; j < n; ++j)
      {
        MOSEKCALL(res, MSK_getxxslice(task, MSK_SOL_ITR, offsetx + j, offsetx + j + 1, &xj));
        expret += mu[j] * xj;
      }

      MOSEKCALL(res, MSK_getxxslice(task, MSK_SOL_ITR, offsets + 0, offsets + 1, &stddev));

      printf("%-12.3e  %-12.3e  %-12.3e\n", alpha, expret, stddev);
    }
    else
    {
      printf("An error occurred when solving for alpha=%e\n", alpha);
    }
  }

  MSK_deletetask(&task);
  MSK_deleteenv(&env);

  return ( 0 );
}