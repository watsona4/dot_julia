/*
   Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.

   File:      mioinitsol.c

   Purpose:   To demonstrate how to solve a MIP with a start guess.

 */

#include "mosek.h"
#include <stdio.h>

static void MSKAPI printstr(void        *handle,
                            const char str[])
{
  printf("%s", str);
} /* printstr */


int main(int argc, char *argv[])
{
  char         buffer[512];

  const MSKint32t numvar    = 4,
                  numcon    = 1,
                  numintvar = 3;

  MSKrescodee  r;

  MSKenv_t     env;
  MSKtask_t    task;

  double       c[] = { 7.0, 10.0, 1.0, 5.0 };

  MSKboundkeye bkc[] = {MSK_BK_UP};
  double       blc[] = { -MSK_INFINITY};
  double       buc[] = {2.5};

  MSKboundkeye bkx[] = {MSK_BK_LO, MSK_BK_LO, MSK_BK_LO, MSK_BK_LO};
  double       blx[] = {0.0,       0.0,       0.0,      0.0      };
  double       bux[] = {MSK_INFINITY, MSK_INFINITY, MSK_INFINITY, MSK_INFINITY};

  MSKint32t    ptrb[] = {0, 1, 2, 3},
               ptre[] = {1, 2, 3, 4},
               asub[] = {0,   0,   0,   0  };

  double       aval[] = {1.0, 1.0, 1.0, 1.0};
  MSKint32t    intsub[] = {0, 1, 2};
  MSKint32t    j;

  r = MSK_makeenv(&env, NULL);

  if ( r == MSK_RES_OK )
    r = MSK_maketask(env, 0, 0, &task);

  if ( r == MSK_RES_OK )
    r = MSK_linkfunctotaskstream(task, MSK_STREAM_LOG, NULL, printstr);

  if (r == MSK_RES_OK)
    r = MSK_inputdata(task,
                      numcon, numvar,
                      numcon, numvar,
                      c,
                      0.0,
                      ptrb,
                      ptre,
                      asub,
                      aval,
                      bkc,
                      blc,
                      buc,
                      bkx,
                      blx,
                      bux);

  if (r == MSK_RES_OK)
    r = MSK_putobjsense(task, MSK_OBJECTIVE_SENSE_MAXIMIZE);

  for (j = 0; j < numintvar && r == MSK_RES_OK; ++j)
    r = MSK_putvartype(task, intsub[j], MSK_VAR_TYPE_INT);

  /* Construct an initial feasible solution from the
     values of the integer variables specified */
  if (r == MSK_RES_OK)
    r = MSK_putintparam(task, MSK_IPAR_MIO_CONSTRUCT_SOL, MSK_ON);

  if (r == MSK_RES_OK)
  {
    double xx[] = {0.0, 2.0, 0.0};

    /* Assign values 0,2,0 to integer variables */
    r = MSK_putxxslice(task, MSK_SOL_ITG, 0, 3, xx);
  }
  /* solve */

  if (r == MSK_RES_OK)
  {
    MSKrescodee trmcode;
    r = MSK_optimizetrm(task, &trmcode);
  }


  {
    double obj;
    int    isok;

    /* Did mosek construct a feasible initial solution ? */
    if (r == MSK_RES_OK)
      r = MSK_getintinf(task, MSK_IINF_MIO_CONSTRUCT_SOLUTION, &isok);

    if (r == MSK_RES_OK )
      r = MSK_getdouinf(task, MSK_DINF_MIO_CONSTRUCT_SOLUTION_OBJ, &obj);

    if (r == MSK_RES_OK)
    {
      if ( isok > 0 )
        printf("Objective of constructed solution : %-24.12e\n", obj);
      else
        printf("Construction of an initial  integer solution failed\n");
    }
  }

  MSK_deletetask(&task);

  MSK_deleteenv(&env);

  if (r != MSK_RES_OK)
  {
    /* In case of an error print error code and description. */
    char symname[MSK_MAX_STR_LEN];
    char desc[MSK_MAX_STR_LEN];

    printf("An error occurred while optimizing.\n");
    MSK_getcodedesc (r,
                     symname,
                     desc);
    printf("Error %s - '%s'\n", symname, desc);
  }

  return (r);
}