/*
   Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.

   File     :  solvelinear.c

   Purpose  :  To demonstrate the usage of MSK_solvewithbasis
               to solve the linear system:

                1.0  x1             = b1
               -1.0  x0  +  1.0  x1 = b2

               with two different right hand sides

               b = (1.0, -2.0)

               and

               b = (7.0, 0.0)
 */

#include "mosek.h"

static void MSKAPI printstr(void *handle,
                            const char str[])
{
  printf("%s", str);
} /* printstr */


MSKrescodee put_a(MSKtask_t task,
                  double *aval,
                  MSKidxt *asub,
                  MSKidxt *ptrb,
                  MSKidxt *ptre,
                  int numvar,
                  MSKidxt *basis
                 )

{
  MSKrescodee r = MSK_RES_OK;
  int i;
  MSKstakeye *skx = NULL , *skc = NULL;

  skx = (MSKstakeye *) calloc(numvar, sizeof(MSKstakeye));
  if (skx == NULL && numvar)
    r = MSK_RES_ERR_SPACE;

  skc = (MSKstakeye *) calloc(numvar, sizeof(MSKstakeye));
  if (skc == NULL && numvar)
    r = MSK_RES_ERR_SPACE;

  for (i = 0; i < numvar && r == MSK_RES_OK; ++i)
  {
    skx[i] = MSK_SK_BAS;
    skc[i] = MSK_SK_FIX;
  }

  /* Create a coefficient matrix and right hand
     side with the data from the linear system */
  if (r == MSK_RES_OK)
    r = MSK_appendvars(task, numvar);

  if (r == MSK_RES_OK)
    r = MSK_appendcons(task, numvar);

  for (i = 0; i < numvar && r == MSK_RES_OK; ++i)
    r = MSK_putacol(task, i, ptre[i] - ptrb[i], asub + ptrb[i], aval + ptrb[i]);

  for (i = 0; i < numvar && r == MSK_RES_OK; ++i)
    r = MSK_putconbound(task, i, MSK_BK_FX, 0, 0);

  for (i = 0; i < numvar && r == MSK_RES_OK; ++i)
    r = MSK_putvarbound(task, i, MSK_BK_FR, -MSK_INFINITY, MSK_INFINITY);

  /* Allocate space for the solution and set status to unknown */

  if (r == MSK_RES_OK)
    r = MSK_deletesolution(task, MSK_SOL_BAS);

  /* Define a basic solution by specifying
     status keys for variables & constraints. */
  for (i = 0; i < numvar && r == MSK_RES_OK; ++i)
    r = MSK_putsolutioni (
          task,
          MSK_ACC_VAR,
          i,
          MSK_SOL_BAS,
          skx[i],
          0.0,
          0.0,
          0.0,
          0.0);

  for (i = 0; i < numvar && r == MSK_RES_OK; ++i)
    r = MSK_putsolutioni (
          task,
          MSK_ACC_CON,
          i,
          MSK_SOL_BAS,
          skc[i],
          0.0,
          0.0,
          0.0,
          0.0);

  if (r == MSK_RES_OK)
    r = MSK_initbasissolve(task, basis);

  free (skx);
  free (skc);

  return ( r );

}

#define NUMCON 2
#define NUMVAR 2

int main(int argc, const char *argv[])
{
  MSKenv_t  env;
  MSKtask_t task;
  MSKrescodee r = MSK_RES_OK;
  MSKintt   numvar = NUMCON;
  MSKintt   numcon = NUMVAR;   /* we must have numvar == numcon */
  int       i, nz;
  double    aval[] = { -1.0, 1.0, 1.0};
  MSKidxt   asub[] = {1, 0, 1};
  MSKidxt   ptrb[] = {0, 1};
  MSKidxt   ptre[] = {1, 3};

  MSKidxt   bsub[NUMCON];
  double    b[NUMCON];

  MSKidxt   *basis = NULL;

  if (r == MSK_RES_OK)
    r = MSK_makeenv(&env, NULL);

  if ( r == MSK_RES_OK )
    r = MSK_makeemptytask(env, &task);

  if ( r == MSK_RES_OK )
    MSK_linkfunctotaskstream(task, MSK_STREAM_LOG, NULL, printstr);

  basis = (MSKidxt *) calloc(numcon, sizeof(MSKidxt));
  if ( basis == NULL && numvar)
    r = MSK_RES_ERR_SPACE;

  /* Put A matrix and factor A.
     Call this function only once for a given task. */
  if (r == MSK_RES_OK)
    r = put_a( task,
               aval,
               asub,
               ptrb,
               ptre,
               numvar,
               basis
             );

  /* now solve rhs */
  b[0] = 1;
  b[1] = -2;
  bsub[0] = 0;
  bsub[1] = 1;
  nz = 2;

  if (r == MSK_RES_OK)
    r = MSK_solvewithbasis(task, 0, &nz, bsub, b);

  if (r == MSK_RES_OK)
  {
    printf("\nSolution to Bx = b:\n\n");
    /* Print solution and show correspondents
       to original variables in the problem */
    for (i = 0; i < nz; ++i)
    {
      if (basis[bsub[i]] < numcon)
        printf("This should never happen\n");
      else
        printf ("x%d = %e\n", basis[bsub[i]] - numcon , b[bsub[i]] );
    }
  }

  b[0] = 7;
  bsub[0] = 0;
  nz = 1;

  if (r == MSK_RES_OK)
    r = MSK_solvewithbasis(task, 0, &nz, bsub, b);

  if (r == MSK_RES_OK)
  {
    printf("\nSolution to Bx = b:\n\n");
    /* Print solution and show correspondents
       to original variables in the problem */
    for (i = 0; i < nz; ++i)
    {
      if (basis[bsub[i]] < numcon)
        printf("This should never happen\n");
      else
        printf ("x%d = %e\n", basis[bsub[i]] - numcon , b[bsub[i]] );
    }
  }

  free (basis);
  return r;
}