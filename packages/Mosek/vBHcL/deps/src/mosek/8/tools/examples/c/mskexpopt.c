/* 
   Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.

   File:      mskexpopt.c

   Purpose:   Command line interface for solving the exponential optimization problem. 
              The syntax is:      
              
                      mskexpopt filename [-primal | -dual] [-p PARAMETERFILE]
                 
              For instance the 
              
                      mskexpopt expopt1.eo -dual 

              solves expopt1.eo using the dual formulation and writes the solution to 
              the file expopt1.sol.
*/
#include <stdlib.h>
#include <string.h>
#include "mosekinternal.h"
#include "expopt.h"

#define WHICHSOL MSK_SOL_ITR  

static double maxdbl (double x,double y)
{
  return x>y ? x : y;
}

static void MSKAPI printcb(void* handle, const char str[])
{
  printf("%s",str);
}

int main (int argc,const char *argv[])
{
  MSKrescodee  r;
  const char   *geoptfile = NULL, *dflt_solutionfile = NULL;
  const char   *statfile = NULL, *statname = NULL, *statkey = NULL;
  char         *cbuf = NULL;
  int          numanz,solveform = 1,numter,numvar,numcon;  
  int          *subi = NULL,*subk = NULL, *subj = NULL;
  double       *c = NULL,*akj = NULL;
  double       objval;
  MSKprostae   prosta;
  MSKsolstae   solsta;
  MSKenv_t     env;
  MSKtask_t    expopttask;
  expopthand_t expopth = NULL;
  FILE         *f;
  char         buffer[MSK_MAX_STR_LEN],symnam[MSK_MAX_STR_LEN];
  MSKint32t    maxnamelen;
    
  r = MSK_makeenv(&env,
                  #if 0
                  "mosek.dbg"
                  #else
                  NULL
                  #endif
                  );
       
  if (r == MSK_RES_OK)
    MSK_makeemptytask(env,&(expopttask));

  if (r == MSK_RES_OK)
    r = MSK_linkfunctotaskstream(expopttask,MSK_STREAM_LOG,NULL,printcb);
  
  argv ++;
  argc --;
  
  while (argc > 0)
  {
    if (strcmp(argv[0] , "-help") == 0 || strcmp(argv[0] , "-h") == 0 || strcmp(argv[0] , "-?") == 0)
    {
      printf ("Usage:\n     mskexpopt FILENAME [-primal] [-dual] [-p parameterfile] [-sol solutionfile]\n");
      return(0);
    } 
    else if (0==strcmp(argv[0],"-p") && argc > 1)
    {
      argv++;
      argc--;
      r = MSK_readparamfile(expopttask,argv[0]);
      argv++;
      argc--;
    }
    else if (0==strcmp(argv[0],"-dual") && argc > 0)
    {
      argv++;
      argc--;
      solveform = 1;
    }
    else if (0==strcmp(argv[0],"-primal") && argc > 0)
    {
      argv++;
      argc--;
      solveform = -1;
    }
    else if (0==strcmp(argv[0],"-sol") && argc > 1)
    {
      argv++;
      argc--;
    
      
      dflt_solutionfile = argv[0];

      argv++;
      argc--;
    }
    else if (0==strcmp(argv[0],"-statfile") && argc > 1)
    {
      argv++;
      argc--;


      statfile = argv[0];

      argv++;
      argc--;
    }
    else if (0==strcmp(argv[0],"-statname") && argc > 1)
    {
      argv++;
      argc--;


      statname = argv[0];

      argv++;
      argc--;
    }
    else if (0==strcmp(argv[0],"-statkey") && argc > 1)
    {
      argv++;
      argc--;


      statkey = argv[0];

      argv++;
      argc--;
    }
    else
    {
      geoptfile = argv[0];
      argv++;
      argc--;

      /*
      printf("Invalid argument to mskexpopt: %s.\n",argv[0]);
      printf ("Usage:\n     mskexpopt FILENAME [-primal] [-dual] [-p parameterfile]\n");
      return(-1);
      */
    }
  }

  if (geoptfile)
  {
    printf ("Reading '%s'\n",geoptfile);

    if (r == MSK_RES_OK)
      r = MSK_expoptread(env,
                         geoptfile,
                         &numcon,
                         &numvar,
                         &numter,
                         &subi,
                         &c,
                         &subk,
                         &subj,
                         &akj,
                         &numanz);
    
  }
  else
  {
    printf("No filename given.\n");
    printf ("Usage:\n     mskexpopt FILENAME [-primal] [-dual] [-p parameterfile]\n");
    r = MSK_RES_ERR_FILE_OPEN;
  }

  if ( r==MSK_RES_OK )
  {
    double *xx=NULL,*y=NULL;

    printf("Data setup for expopt begin.\n");   
      
    r =  MSK_expoptsetup(expopttask,
                         solveform,
                         numcon,
                         numvar,
                         numter,
                         subi,
                         c,
                         subk,
                         subj,
                         akj,
                         numanz,
                         &expopth);
    printf("Data setup for expopt end.\n");
  
    if (r == MSK_RES_OK && numvar)
    {
      xx = MSK_calloctask(expopttask,numvar,sizeof(double));
      if (xx == NULL)
        r = MSK_RES_ERR_SPACE;
    }
  
    if (r == MSK_RES_OK && numter)
    {
      y = MSK_calloctask(expopttask,numter,sizeof(double));
      if (y == NULL)
        r = MSK_RES_ERR_SPACE;
    }
     
    if (r == MSK_RES_OK && statfile)
    {
      MSK_startstat(expopttask);
      MSK_putstrparam(expopttask,MSK_SPAR_STAT_FILE_NAME,statfile);
      MSK_putstrparam(expopttask,MSK_SPAR_STAT_NAME,statname);
      MSK_putstrparam(expopttask,MSK_SPAR_STAT_KEY,statkey);
      MSK_putintparam(expopttask, MSK_IPAR_AUTO_UPDATE_SOL_INFO, MSK_ON);
      MSK_putintparam(expopttask, MSK_IPAR_COMPRESS_STATFILE, MSK_OFF);
    }
  
    if (r == MSK_RES_OK)
      r = MSK_expoptimize( expopttask,
                           &prosta,
                           &solsta,
                           &objval,
                           xx,
                           y,
                           &expopth);
  
    MSK_solutionsummary(expopttask, MSK_STREAM_MSG);

    if (statfile && (r == MSK_RES_OK || r == MSK_RES_TRM_STALL || r == MSK_RES_TRM_MAX_ITERATIONS))
      MSK_appendstat(expopttask);
  
    /* Print solution summary */
  
    
    if (r == MSK_RES_OK)        
      r = MSK_getmaxnamelen(expopttask,&maxnamelen);
            
    if (r == MSK_RES_OK)
    {
      cbuf = MSK_calloctask(expopttask,(maxnamelen<256 ? 256:maxnamelen)+1,sizeof(char));
      if (cbuf == NULL)
        r = MSK_RES_ERR_SPACE;
    }
    
    if (r == MSK_RES_OK)
    {
      printf ("\nExpopt solution summary:\n");
  
      if (solveform == 1)
      {
      switch(prosta)
      {
        case MSK_PRO_STA_DUAL_INFEAS:
          printf("PROBLEM STATUS      : PRIMAL_INFEASIBLE\n");
          break;
  
        case MSK_PRO_STA_PRIM_INFEAS:
          printf("PROBLEM STATUS      : DUAL_INFEASIBLE\n");
          break;
        default:
          if (r == MSK_RES_OK)
            r = MSK_prostatostr(expopttask,prosta,cbuf);
          printf("PROBLEM STATUS      : %s\n",cbuf);
          break;
      }
      }
      else
      {
        if (r == MSK_RES_OK)
          r = MSK_prostatostr(expopttask,prosta,cbuf);
        printf("PROBLEM STATUS      : %s\n",cbuf);
      }
    }
  
    if (r == MSK_RES_OK)
    {
      switch (solsta)
      {
        case MSK_SOL_STA_OPTIMAL:
          printf("Solution status     : %s\n","OPTIMAL");
          break;      
        default:
          printf("Solution status     : %s\n","UNKNOWN");
          break;      
      }
    
      printf("Primal - objective  : %-16.10e\n",objval);
    } 
    /* write a solution file */
   
    if (r == MSK_RES_OK)
    {
      size_t l   = strlen(geoptfile);
      char *fn  = NULL;
  
      if (! dflt_solutionfile)
        fn = MSK_calloctask(expopttask,l+5,sizeof(char));
      if ( fn || dflt_solutionfile )
      {
        int i;
        
        if ( fn )
        {
          for(l=0; geoptfile[l] && geoptfile[l]!='.'; ++l)
            fn[l] = geoptfile[l];
        
          strcpy(fn+l,".sol");
        }      
  
        printf("\n");
  
        if ( ! dflt_solutionfile )
        {
          printf("Writing solution file to - %s\n",fn);
          f = fopen(fn,"wt");
        }
        else
        {
          printf("Writing solution file to - %s\n",dflt_solutionfile);
          f = fopen(dflt_solutionfile,"wt");
        }
        
        if (f == NULL)
          r = MSK_RES_ERR_FILE_OPEN;
        
        if (r == MSK_RES_OK)
        {
          
          if (solveform == 1)
          {
            switch(prosta)
            {
              case MSK_PRO_STA_DUAL_INFEAS:
                fprintf(f,"PROBLEM STATUS      : PRIMAL_INFEASIBLE\n");
                break;
                
              case MSK_PRO_STA_PRIM_INFEAS:
                fprintf(f,"PROBLEM STATUS      : DUAL_INFEASIBLE\n");
                break;
              default:
                if (r == MSK_RES_OK)
                  r = MSK_prostatostr(expopttask,prosta,cbuf);
                fprintf(f,"PROBLEM STATUS      : %s\n",cbuf);
                break;
            }
          }
          else
          {
            if (r == MSK_RES_OK)
              r = MSK_prostatostr(expopttask,prosta,cbuf);
            fprintf(f,"PROBLEM STATUS      : %s\n",cbuf);
          }
            
      
        switch (solsta)
        {
          case MSK_SOL_STA_OPTIMAL:
            fprintf(f,"SOLUTION STATUS     : %s\n","OPTIMAL");
            break;      
          case MSK_SOL_STA_PRIM_INFEAS_CER:
          case MSK_SOL_STA_DUAL_INFEAS_CER:
            fprintf(f,"SOLUTION STATUS     : %s\n","INFEASIBLE");
            break;
          default:
            fprintf(f,"SOLUTION STATUS     : %s\n","UNKNOWN");
            break;      
        }
          
          fprintf(f,"OBJECTIVE           : %e\n",objval);
          fprintf(f,"\n");
          fprintf(f,"PRIMAL VARIABLES\n");
          fprintf(f,"%-8s%-16s\n","INDEX","ACTIVITY");   
          
          for (i=0;i<numvar && r == MSK_RES_OK;++i)
          {          
            fprintf(f,"%-8d%-16.6e\n",i+1,xx[i]); 
          }
        
          if (solveform == 1)
          {
            fprintf(f,"\n");
            fprintf(f,"DUAL VARIABLES\n");
            fprintf(f,"%-8s%-16s\n","INDEX","ACTIVITY");
            
            for (i=0;i<numter && r == MSK_RES_OK;++i)
            {          
            fprintf(f,"%-8d%-16.6e\n",i+1,y[i]); 
            }
          }
          
          if ( fn )
            MSK_freetask(expopttask,fn);
  
          if (f != NULL)
            fclose(f);
        }
      }
    }

    MSK_freetask(expopttask,xx);
    MSK_freetask(expopttask,y);
  }

  MSK_freetask(expopttask,cbuf);
  MSK_expoptfree(expopttask,
         &expopth
          );

  MSK_freeenv(env,subi);
  MSK_freeenv(env,c);
  MSK_freeenv(env,subk);
  MSK_freeenv(env,subj);
  MSK_freeenv(env,akj);
  
  printf("Return code: %d\n",r);
  if ( r!=MSK_RES_OK )
  { 
    MSK_getcodedesc(r,symnam,buffer);
    printf("Description: %s [%s]\n",symnam,buffer);
  }
  
  if (expopttask)
    MSK_deletetask(&expopttask);
  
  if (env)
    MSK_deleteenv(&env);
  
  return ( r );
}

