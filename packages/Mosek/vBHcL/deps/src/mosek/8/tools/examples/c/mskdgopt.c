/* 
   Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.

   File:      mskdgopt.c

   Purpose:
              To solve the dual geometric programming problem.
              Input consists of:
           
                1. An MPS file containing the linear part of the problem
                2. A file containing information about the nonlinear objective.

              E.g

                msdgopt dgo.mps dgo.f
*/


#include "dgopt.h"

static void MSKAPI printstr(void       *handle,
                            const char str[])
{
  printf("%s",str);
} /* printstr */


int main (int argc,char ** argv)
{
  int         numvar,numcon,t,i;
  double      *v = NULL;
  int         *p = NULL;
  char        buffer[MSK_MAX_STR_LEN],symnam[MSK_MAX_STR_LEN];
  dgohand_t   nlh=NULL;
  MSKenv_t    env;
  MSKrescodee r = MSK_RES_OK;
  MSKtask_t   task;
   
  /* Create the mosek environment. */
  r = MSK_makeenv(&env,NULL);

  if ( r==MSK_RES_OK )
  {  
    /* Make the optimization task. */
    r = MSK_makeemptytask(env,&task);
 
    if ( r==MSK_RES_OK )
      MSK_linkfunctotaskstream(task,MSK_STREAM_LOG,NULL,printstr);

    if ( r==MSK_RES_OK && argc>3 )
    {
      /* Read parameter file if defined. */
      r = MSK_readparamfile(task,argv[3]);
    }
  }
  
  if ( r==MSK_RES_OK )
    r = MSK_readdata(task,argv[1]);
  
  if (r == MSK_RES_OK)
    r =  MSK_dgoread( task,
                      argv[2],
                      &numvar,    
                      &numcon,    
                      &t,         
                      &v,        
                      &p
                      );
  
  
  if (r == MSK_RES_OK)
    r = MSK_dgosetup(task,
                     numvar,
                     numcon,
                     t,
                     v,
                     p,   
                     &nlh);
  
  if (r == MSK_RES_OK)
    r = MSK_optimize(task);

  if (r == MSK_RES_OK)
  {
    MSK_putintparam(task,MSK_IPAR_WRITE_GENERIC_NAMES,MSK_ON);
    
    MSK_solutionsummary(task,MSK_STREAM_MSG);

    /*
     * The solution is written to the file dgopt.sol.
     */
    
    r = MSK_writesolution(task,MSK_SOL_ITR,"dgopt.sol");
  }
          
  MSK_freetask(task,v);
  MSK_freetask(task,p);

  if ( nlh )
    MSK_freedgo(task,&nlh);   
  
  MSK_deletetask(&task);
    
  MSK_deleteenv(&env);
  
  printf("Return code: %d\n",r);
  if ( r!=MSK_RES_OK )
  { 
    MSK_getcodedesc(r,symnam,buffer);
    printf("Description: %s [%s]\n",symnam,buffer);
  }
  
  return ( r ); 
}  