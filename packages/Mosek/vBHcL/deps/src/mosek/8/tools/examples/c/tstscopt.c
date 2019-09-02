/* 
   Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved. 

   File     : tstscopt.c

   Purpose  : To solve the problem

              minimize    x_1 - log(x_3)
              subject to  x_1^2 + x_2^2 <= 1
                          x_1 + 2*x_2 - x_3 = 0
                          x_3 >=0
 */

#include "scopt-ext.h"

#define NUMOPRO  1 /* Number of nonlinear expressions in the obj. */
#define NUMOPRC  2 /* Number of nonlinear expressions in the con. */
#define NUMVAR   3 /* Number of variables.     */
#define NUMCON   2 /* Number of constraints.   */
#define NUMANZ   3 /* Number of non-zeros in A. */

static void MSKAPI printstr(void *handle,
                            const char str[])
{
  printf("%s",str);
} /* printstr */

int main()
{
  char         buffer[MSK_MAX_STR_LEN];
  double       oprfo[NUMOPRO],oprgo[NUMOPRO],oprho[NUMOPRO],
               oprfc[NUMOPRC],oprgc[NUMOPRC],oprhc[NUMOPRC],
               c[NUMVAR],aval[NUMANZ],
               blc[NUMCON],buc[NUMCON],blx[NUMVAR],bux[NUMVAR];
  int          numopro,numoprc,
               numcon=NUMCON,numvar=NUMVAR,
               opro[NUMOPRO],oprjo[NUMOPRO],
               oprc[NUMOPRC],opric[NUMOPRC],oprjc[NUMOPRC],
               aptrb[NUMVAR],aptre[NUMVAR],asub[NUMANZ];
  MSKboundkeye bkc[NUMCON],bkx[NUMVAR];
  MSKenv_t     env;
  MSKrescodee  r;
  MSKtask_t    task;
  schand_t     sch;

  /* Specify nonlinear terms in the objective. */
  numopro  = NUMOPRO;
  opro[0]  = MSK_OPR_LOG; /* Defined in scopt.h */
  oprjo[0] = 2;
  oprfo[0] = -1.0;
  oprgo[0] = 1.0;  /* This value is never used. */
  oprho[0] = 0.0;

  /* Specify nonlinear terms in the constraints. */
  numoprc  = NUMOPRC;
  
  oprc[0]  = MSK_OPR_POW;
  opric[0] = 0;
  oprjc[0] = 0;
  oprfc[0] = 1.0;
  oprgc[0] = 2.0;
  oprhc[0] = 0.0;

  oprc[1]  = MSK_OPR_POW;
  opric[1] = 0;
  oprjc[1] = 1;
  oprfc[1] = 1.0;
  oprgc[1] = 2.0;
  oprhc[1] = 0.0;

  /* Specify c */
  c[0] = 1.0; c[1] = 0.0; c[2] = 0.0;

  /* Specify a. */
  aptrb[0] = 0;   aptrb[1] = 1;   aptrb[2] = 2;
  aptre[0] = 1;   aptre[1] = 2;   aptre[2] = 3;
  asub[0]  = 1;   asub[1]  = 1;   asub[2]  = 1;
  aval[0]  = 1.0; aval[1]  = 2.0; aval[2]  = -1.0;

  /* Specify bounds for constraints. */
  bkc[0] = MSK_BK_UP;     bkc[1] = MSK_BK_FX;
  blc[0] = -MSK_INFINITY; blc[1] = 0.0;
  buc[0] = 1.0;           buc[1] = 0.0;

  /* Specify bounds for variables. */
  bkx[0] = MSK_BK_LO;      bkx[1] = MSK_BK_LO;     bkx[2] = MSK_BK_LO;
  blx[0] = 0.0;            blx[1] = 0.1;           blx[2] = 0.0;
  bux[0] = MSK_INFINITY;   bux[1] = MSK_INFINITY;  bux[2] = MSK_INFINITY;

  /* Create  the mosek environment. */
  r = MSK_makeenv(&env,NULL);
 
  if ( r==MSK_RES_OK )
  {  
    /* Make the optimization task. */
    r = MSK_makeemptytask(env,&task);
    if ( r==MSK_RES_OK )
      MSK_linkfunctotaskstream(task,MSK_STREAM_LOG,NULL,printstr);

    if ( r==MSK_RES_OK )
    {
      /* Setup the linear part of the problem. */
      r = MSK_inputdata(task,
                        numcon,numvar,
                        numcon,numvar,
                        c,0.0,
                        aptrb,aptre,
                        asub,aval,
                        bkc,blc,buc,
                        bkx,blx,bux);
    }
   
    if ( r== MSK_RES_OK )
    {
      /* Set-up of nonlinear expressions. */
      r = MSK_scbegin(task,
                      numopro,opro,oprjo,oprfo,oprgo,oprho,
                      numoprc,oprc,opric,oprjc,oprfc,oprgc,oprhc,
                      &sch);

      if ( r==MSK_RES_OK )
      {
        printf("Start optimizing\n");

        r = MSK_optimize(task);

        printf("Done optimizing\n");

        MSK_solutionsummary(task,MSK_STREAM_MSG);
      }
       
      /* The nonlinear expressions are no longer needed. */
      MSK_scend(task,&sch);
    }
    MSK_deletetask(&task);
  }
  MSK_deleteenv(&env);
       
  printf("Return code: %d\n",r);
  if ( r!=MSK_RES_OK )
  {
    MSK_getcodedesc(r,buffer,NULL);
    printf("Description: %s\n",buffer);
  }

  return r;
} /* main */