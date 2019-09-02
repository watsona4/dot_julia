/*
  File : case_portfolio_3.c

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
  const MSKint32t n       = 3;
  const double    w       = 1.0,
                  x0[]    = {0.0, 0.0, 0.0},
                  gamma   = 0.05,
                  mu[]    = {0.1073,  0.0737,  0.0627},
                  m[]     = {0.01, 0.01, 0.01},
                  GT[][3] = {{0.1667,  0.0232,  0.0013},
                             {0.0000,  0.1033, -0.0022},
                             {0.0000,  0.0000,  0.0338}
                            };
  double          b[3]    = {0.0, -1.0 / 8.0, 0.0};
  double          rtemp,
                  expret,
                  stddev,
                  xj;
  MSKenv_t        env;
  MSKint32t       k, i, j,
                  offsetx, offsets, offsett, offsetc,
                  offsetv, offsetz, offsetf, offsetg;
  MSKrescodee     res = MSK_RES_OK;
  MSKtask_t       task;

  /* Initial setup. */
  env  = NULL;
  task = NULL;
  MOSEKCALL(res, MSK_makeenv(&env, NULL));
  MOSEKCALL(res, MSK_maketask(env, 0, 0, &task));
  MOSEKCALL(res, MSK_linkfunctotaskstream(task, MSK_STREAM_LOG, NULL, printstr));

  rtemp = w;
  for (k = 0; k < n; ++k)
    rtemp += x0[k];

  /* Constraints. */
  MOSEKCALL(res, MSK_appendcons(task, 1 + 9 * n));
  MOSEKCALL(res, MSK_putconbound(task, 0, MSK_BK_FX, w, w));
  sprintf(buf, "%s", "budget");
  MOSEKCALL(res, MSK_putconname(task, 0, buf));

  for (i = 0; i < n; ++i)
  {
    MOSEKCALL(res, MSK_putconbound(task, 1 + i, MSK_BK_FX, 0.0, 0.0));
    sprintf(buf, "GT[%d]", 1 + i);
    MOSEKCALL(res, MSK_putconname(task, 1 + i, buf));
  }

  for (i = 0; i < n; ++i)
  {
    MOSEKCALL(res, MSK_putconbound(task, 1 + n + i, MSK_BK_LO, -x0[i], MSK_INFINITY));
    sprintf(buf, "zabs1[%d]", 1 + i);
    MOSEKCALL(res, MSK_putconname(task, 1 + n + i, buf));
  }

  for (i = 0; i < n; ++i)
  {
    MOSEKCALL(res, MSK_putconbound(task, 1 + 2 * n + i, MSK_BK_LO, x0[i], MSK_INFINITY));
    sprintf(buf, "zabs2[%d]", 1 + i);
    MOSEKCALL(res, MSK_putconname(task, 1 + 2 * n + i, buf));
  }

  for (i = 0; i < n; ++i)
  {
    for (k = 0; k < 3; ++k)
    {
      MOSEKCALL(res, MSK_putconbound(task, 1 + 3 * n + 3 * i + k, MSK_BK_FX, 0.0, 0.0));
      sprintf(buf, "f[%d,%d]", 1 + i, 1 + k);
      MOSEKCALL(res, MSK_putconname(task, 1 + 3 * n + 3 * i + k, buf));
    }
  }

  for (i = 0; i < n; ++i)
  {
    for (k = 0; k < 3; ++k)
    {
      MOSEKCALL(res, MSK_putconbound(task, 1 + 6 * n + 3 * i + k, MSK_BK_FX, b[k], b[k]));
      sprintf(buf, "g[%d,%d]", 1 + i, 1 + k);
      MOSEKCALL(res, MSK_putconname(task, 1 + 6 * n + 3 * i + k, buf));
    }
  }

  /* Offsets of variables into the (serialized) API variable. */
  offsetx = 0;
  offsets = n;
  offsett = n + 1;
  offsetc = 2 * n + 1;
  offsetv = 3 * n + 1;
  offsetz = 4 * n + 1;
  offsetf = 5 * n + 1;
  offsetg = 8 * n + 1;


  /* Variables. */
  MOSEKCALL(res, MSK_appendvars(task, 11 * n + 1));

  /* x variables. */
  for (j = 0; j < n; ++j)
  {
    MOSEKCALL(res, MSK_putcj(task, offsetx + j, mu[j]));
    MOSEKCALL(res, MSK_putaij(task, 0, offsetx + j, 1.0));
    for (k = 0; k < n; ++k)
      if ( GT[k][j] != 0.0 )
        MOSEKCALL(res, MSK_putaij(task, 1 + k, offsetx + j, GT[k][j]));
    MOSEKCALL(res, MSK_putaij(task, 1 + n + j, offsetx + j, -1.0));
    MOSEKCALL(res, MSK_putaij(task, 1 + 2 * n + j, offsetx + j, 1.0));

    MOSEKCALL(res, MSK_putvarbound(task, offsetx + j, MSK_BK_LO, 0.0, MSK_INFINITY));
    sprintf(buf, "x[%d]", 1 + j);
    MOSEKCALL(res, MSK_putvarname(task, offsetx + j, buf));
  }

  /* s variable. */
  MOSEKCALL(res, MSK_putvarbound(task, offsets + 0, MSK_BK_FX, gamma, gamma));
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

  /* c variables. */
  for (j = 0; j < n; ++j)
  {
    MOSEKCALL(res, MSK_putaij(task, 0, offsetc + j, m[j]));
    MOSEKCALL(res, MSK_putaij(task, 1 + 3 * n + 3 * j + 1, offsetc + j, 1.0));
    MOSEKCALL(res, MSK_putvarbound(task, offsetc + j, MSK_BK_FR, -MSK_INFINITY, MSK_INFINITY));
    sprintf(buf, "c[%d]", 1 + j);
    MOSEKCALL(res, MSK_putvarname(task, offsetc + j, buf));
  }

  /* v variables. */
  for (j = 0; j < n; ++j)
  {
    MOSEKCALL(res, MSK_putaij(task, 1 + 3 * n + 3 * j + 0, offsetv + j, 1.0));
    MOSEKCALL(res, MSK_putaij(task, 1 + 6 * n + 3 * j + 2, offsetv + j, 1.0));
    MOSEKCALL(res, MSK_putvarbound(task, offsetv + j, MSK_BK_FR, -MSK_INFINITY, MSK_INFINITY));
    sprintf(buf, "v[%d]", 1 + j);
    MOSEKCALL(res, MSK_putvarname(task, offsetv + j, buf));
  }

  /* z variables. */
  for (j = 0; j < n; ++j)
  {
    MOSEKCALL(res, MSK_putaij(task, 1 + 1 * n + j, offsetz + j, 1.0));
    MOSEKCALL(res, MSK_putaij(task, 1 + 2 * n + j, offsetz + j, 1.0));
    MOSEKCALL(res, MSK_putaij(task, 1 + 3 * n + 3 * j + 2, offsetz + j, 1.0));
    MOSEKCALL(res, MSK_putaij(task, 1 + 6 * n + 3 * j + 0, offsetz + j, 1.0));
    MOSEKCALL(res, MSK_putvarbound(task, offsetz + j, MSK_BK_FR, -MSK_INFINITY, MSK_INFINITY));
    sprintf(buf, "z[%d]", 1 + j);
    MOSEKCALL(res, MSK_putvarname(task, offsetz + j, buf));
  }

  /* f variables. */
  for (j = 0; j < n; ++j)
  {
    for (k = 0; k < 3; ++k)
    {
      MOSEKCALL(res, MSK_putaij(task, 1 + 3 * n + 3 * j + k, offsetf + 3 * j + k, -1.0));
      MOSEKCALL(res, MSK_putvarbound(task, offsetf + 3 * j + k, MSK_BK_FR, -MSK_INFINITY, MSK_INFINITY));
      sprintf(buf, "f[%d,%d]", 1 + j, 1 + k);
      MOSEKCALL(res, MSK_putvarname(task, offsetf + 3 * j + k, buf));
    }
  }

  /* g variables. */
  for (j = 0; j < n; ++j)
  {
    for (k = 0; k < 3; ++k)
    {
      MOSEKCALL(res, MSK_putaij(task, 1 + 6 * n + 3 * j + k, offsetg + 3 * j + k, -1.0));
      MOSEKCALL(res, MSK_putvarbound(task, offsetg + 3 * j + k, MSK_BK_FR, -MSK_INFINITY, MSK_INFINITY));
      sprintf(buf, "g[%d,%d]", 1 + j, 1 + k);
      MOSEKCALL(res, MSK_putvarname(task, offsetg + 3 * j + k, buf));
    }
  }
  if ( res == MSK_RES_OK )
  {
    /* sub should be n+1 long i.e. the dimmension of the cone. */
    MSKint32t *sub = (MSKint32t *) MSK_calloctask(task, 3 >= n + 1 ? 3 : n + 1, sizeof(MSKint32t));

    if ( sub )
    {
      sub[0] = offsets + 0;
      for (j = 0; j < n; ++j)
        sub[j + 1] = offsett + j;

      MOSEKCALL(res, MSK_appendcone(task, MSK_CT_QUAD, 0.0, n + 1, sub));
      MOSEKCALL(res, MSK_putconename(task, 0, "stddev"));

      for (k = 0; k < n; ++k)
      {
        MOSEKCALL(res, MSK_appendconeseq(task, MSK_CT_RQUAD, 0.0, 3, offsetf + k * 3));
        sprintf(buf, "f[%d]", 1 + k);
        MOSEKCALL(res, MSK_putconename(task, 1 + k, buf));
      }

      for (k = 0; k < n; ++k)
      {
        MOSEKCALL(res, MSK_appendconeseq(task, MSK_CT_RQUAD, 0.0, 3, offsetg + k * 3));
        sprintf(buf, "g[%d]", 1 + k);
        MOSEKCALL(res, MSK_putconename(task, 1 + n + k, buf));
      }

      MSK_freetask(task, sub);
    }
    else
      res = MSK_RES_ERR_SPACE;
  }

  MOSEKCALL(res, MSK_putobjsense(task, MSK_OBJECTIVE_SENSE_MAXIMIZE));

#if 1
  /* no log output. */
#else
  MOSEKCALL(res, MSK_putintparam(task, MSK_IPAR_LOG, 0));
#endif


#if 0
  /* Dump the problem to a human readable OPF file. */
  MOSEKCALL(res, MSK_writedata(task, "dump.opf"));
#endif

  MOSEKCALL(res, MSK_optimize(task));

  /* Display the solution summary for quick inspection of results. */
#if 1
  MSK_solutionsummary(task, MSK_STREAM_MSG);
#endif

  if ( res == MSK_RES_OK )
  {
    expret = 0.0;
    stddev = 0.0;

    for (j = 0; j < n; ++j)
    {
      MOSEKCALL(res, MSK_getxxslice(task, MSK_SOL_ITR, offsetx + j, offsetx + j + 1, &xj));
      expret += mu[j] * xj;
    }

    MOSEKCALL(res, MSK_getxxslice(task, MSK_SOL_ITR, offsets + 0, offsets + 1, &stddev));

    printf("\nExpected return %e for gamma %e\n", expret, stddev);
  }

  MSK_deletetask(&task);
  MSK_deleteenv(&env);

  return ( 0 );
}