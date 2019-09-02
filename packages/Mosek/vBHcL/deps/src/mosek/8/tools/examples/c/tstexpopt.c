/*
   Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.

   File     : tstexpopt.c

   Purpose  : To demonstrate a simple interface for exponential optimization.
*/
#include <string.h>

#include "expopt.h"

void MSKAPI printcb(void* handle, const char str[])
{
  printf("%s",str);
}

  
int main (int argc, char **argv)
{
  int          r = MSK_RES_OK, numcon = 1, numvar = 3 , numter = 5;
  
  int          subi[]   = {0,0,0,1,1};
  int          subk[]   = {0,0,0,1,1,2,2,2,3,3,4,4};
  double       c[]      = {40.0,20.0,40.0,0.333333,1.333333};
  int          subj[]   = {0,1,2,0,2,0,1,2,0,1,1,2};
  double       akj[]    = {-1,-0.5,-1.0,1.0,1.0,1.0,1.0,1.0,-2.0,-2.0,0.5,-1.0};
  int          numanz   = 12;
  double       objval;
  double       xx[3];
  double       y[5];
  MSKenv_t     env;
  MSKprostae   prosta;
  MSKsolstae   solsta;
  MSKtask_t    expopttask;
  expopthand_t expopthnd = NULL;
  /* Pointer to data structure that holds nonlinear information */
  
  if (r == MSK_RES_OK)
    r = MSK_makeenv (&env,NULL); 
        
  if (r == MSK_RES_OK)
    MSK_makeemptytask(env,&expopttask);
  
  if (r == MSK_RES_OK)
    r = MSK_linkfunctotaskstream(expopttask,MSK_STREAM_LOG,NULL,printcb);

  if (r == MSK_RES_OK)
  {
    /* Initialize expopttask with problem data */    
    r =  MSK_expoptsetup(expopttask,
                         1, /* Solve the dual formulation */      
                         numcon,
                         numvar,
                         numter,
                         subi,
                         c,
                         subk,
                         subj,
                         akj,
                         numanz,
                         &expopthnd
                         /* Pointer to data structure holding nonlinear data */
                         );
  }

  /* Any parameter can now be changed with standard mosek function calls */ 
  if (r == MSK_RES_OK)
    r = MSK_putintparam(expopttask,MSK_IPAR_INTPNT_MAX_ITERATIONS,200); 

  /* Optimize, xx holds the primal optimal solution,
   y holds solution to the dual problem if the dual formulation is used
  */
  
  if (r == MSK_RES_OK)
    r = MSK_expoptimize(expopttask,
                        &prosta,
                        &solsta,
                        &objval,
                        xx,
                        y,
                        &expopthnd);
    
  /* Free data allocated by expoptsetup */
  if (expopthnd)
    MSK_expoptfree(expopttask,
                   &expopthnd);
  
  MSK_deletetask(&expopttask);
  MSK_deleteenv(&env);
  
}
  