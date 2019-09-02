/* 
   Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.

   File:      dgopt.c

   Purpose:   To solve dual geometric optimization problems 
              using the MOSEK API.

              On the command line type

              dgopt go.mps go.f

              where

                go.mps: Is an MPS file specifing
                        the linear part of the
                        problem.

                go.f  : Is an (ASCII) file specifying
                        the nonlinear part of the
                        problem.
 */  
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#include "dgopt.h"
#include "mosek.h" /* Include the MOSEK definition file. */


#define MAX_LINE_LENGTH 256
#define DEBUG           0
#define PRINT_GRDLAG    0
#define PRINT_HESVAL    0
#define OBJSCAL         1.0
#define DUMPHESSIAN     0

#if DEBUG
#include <assert.h>
#endif

typedef struct
        {
          /*
           * Data structure for storing
           * data about the nonlinear
           * function in the objective.
           */

          MSKtask_t   task;

          MSKint32t   n;        /* Number of variables.  */
          MSKint32t   t;        /* Number of terms in
                                   the objective of the primal problem. */
          MSKint32t   *p;
          MSKint32t   numhesnz; /* Number of non-zeros in
                                   the Hessian.          */
        } nlhandt;

typedef nlhandt *nlhand_t;


static int MSKAPI printnldata(nlhand_t nlh)
{
  MSKidxt i;
  
  printf ("* Begin: dgo nl data debug. *\n");

  printf ("n = %d, t = %d\n",nlh->n,nlh->t);

  for (i=0; i<nlh->t + 1;++i)
    printf("p[%d] = %d\n",i,nlh->p[i]);

  
  printf ("* End: dgo nl data debug. *\n");

  return 0;
} /* printnldata */


static int MSKAPI dgostruc(void            *nlhandle,
                           MSKint32t       *numgrdobjnz,
                           MSKint32t       *grdobjsub,
                           MSKint32t       i,
                           int             *convali,
                           MSKint32t       *grdconinz,
                           MSKint32t       *grdconisub,
                           MSKint32t       yo,
                           MSKint32t       numycnz,
                           const MSKint32t *ycsub,
                           MSKint32t       maxnumhesnz,
                           MSKint32t       *numhesnz,
                           MSKint32t       *hessubi,
                           MSKint32t       *hessubj)
/* Purpose: Provide information to MOSEK about the problem structure
            and sparsity.
 */
{
  MSKint32t j,k,l; 
  nlhand_t  nlh;

  nlh = (nlhand_t) nlhandle;

  MSK_checkmemtask(nlh->task,__FILE__,__LINE__);

  if ( numgrdobjnz )
  {
    /* All the variables appear nonlinearly
     * in the objective.
     */


    numgrdobjnz[0] = 0;

    for(k=0; k<1; ++k)
    {
      for(j=nlh->p[k]; j<nlh->p[k+1]; ++j)
      {
        if ( grdobjsub )
          grdobjsub[numgrdobjnz[0]] = j;

        ++ numgrdobjnz[0];
      }
    }   

    for(k=1; k<nlh->t; ++k)
    {
      if ( nlh->p[k+1]-nlh->p[k]>1 )
      {
        for(j=nlh->p[k]; j<nlh->p[k+1]; ++j)
        {
          if ( grdobjsub )
            grdobjsub[numgrdobjnz[0]] = j;

          ++ numgrdobjnz[0];
        }
      }
    }   
  }

  if ( convali )
    convali[0] = 0;    /* Zero because no nonlinear
                        * expression in the constraints.
                        */

  if ( grdconinz )
    grdconinz[0] = 0;  /* Zero because no nonlinear
                        * expression in the constraints.
                        */

  if ( numhesnz )
  {
    if ( yo )
      numhesnz[0] = nlh->numhesnz;
    else
      numhesnz[0] = 0;
  }

  if ( maxnumhesnz )
  {
    /* Should return information about the Hessian too. */

    if ( maxnumhesnz<numhesnz[0] )
    {
      /* Not enough space have been allocated for
       * storing the Hessian.
       */

      return ( 1 );
    }
    else
    {
      if ( yo )
      {
        if ( hessubi && hessubj )
        {
          /*
           * Compute and store the sparsity pattern of the
           * Hessian of the Lagrangian.
           */

          l = 0;
          for(j=nlh->p[0]; j<nlh->p[1]; ++j)
          {
            hessubi[l]  = j;
            hessubj[l]  = j;
                       ++ l;
          }

          for(k=1; k<nlh->t; ++k)
          {
            for(j=nlh->p[k]; j<nlh->p[k+1]; ++j)
            {
              for(i=j; i<nlh->p[k+1]; ++i)
              {
                if (nlh->p[k+1]-nlh->p[k]>1)
                {
                  hessubi[l]  = i;
                  hessubj[l]  = j;
                             ++ l;
                }
              }
            }
          }
        }
      }
    }
  }

  return ( 0 );
} /* dgostruc */

static int MSKAPI dgoeval(void             *nlhandle,
                          const double  *xx,
                          double           yo,
                          const double  *yc,
                          double           *objval,
                          MSKint32t        *numgrdobjnz,
                          MSKint32t        *grdobjsub,
                          double           *grdobjval,
                          MSKint32t        numi,
                          const MSKidxt *subi,
                          double           *conval,
                          const MSKintt *grdconptrb,
                          const MSKintt *grdconptre,
                          const MSKidxt *grdconsub,
                          double           *grdconval,
                          double           *grdlag,
                          MSKint32t        maxnumhesnz,
                          MSKint32t        *numhesnz,
                          MSKint32t        *hessubi,
                          MSKint32t        *hessubj,
                          double           *hesval)
/* Purpose: To evaluate the nonlinear function and return the
            requested information to MOSEK.
 */
{
  double    rtemp;
  MSKint32t i,j,k,l,itemp;
  nlhand_t  nlh;

  nlh = (nlhand_t) nlhandle;

  #if 0
  MSK_checkmemtask(nlh->task,__FILE__,__LINE__);
  #endif
  
  if ( objval )
  {
    /* f(x) is computed and stored in objval[0]. */
    objval[0] = 0.0;


    for(k=0; k<nlh->t; ++k)
    {
      if ( nlh->p[k+1]-nlh->p[k]>1 )
      {
        for(j=nlh->p[k]; j<nlh->p[k+1]; ++j)
        {
          if ( xx[j]<=0.0 )
          {
            return (1);
          }
        }
      }
    }
            
    for(k=0; k<1; ++k)
    {
      for(j=nlh->p[k]; j<nlh->p[k+1] ; ++j)
      {
        #if DEBUG
        printf("(%d) xx = %p, k = %d, j = %d, nlh = %p, p[0] = %d\n",
               __LINE__,xx,k,j,nlh,nlh->p[0]);
        if ( xx[j]<=0.0 )
          printf("Zero xx[%d]: %e",j,xx[j]);

        assert(xx[j] > 0.0 );
        #endif
        
        objval[0] -= xx[j]*log(xx[j]);
      }
    }

    for(k=1; k<nlh->t; ++k)
    {
      if ( nlh->p[k+1]-nlh->p[k]>1 )
      {
        for(j=nlh->p[k]; j<nlh->p[k+1]; ++j)
        {
#if DEBUG
          if ( xx[j]<=0.0 )
            printf("Zero xx[%d]: %e",j,xx[j]);

          assert(xx[j] > 0);
#endif
          
          objval[0] -= xx[j]*log(xx[j]);
        }
        rtemp = 0.0;

        for(j=nlh->p[k]; j<nlh->p[k+1]; ++j)
          rtemp += xx[j];

        if ( rtemp<=0.0 )
          return ( 1 );

#if DEBUG
        assert(rtemp > 0);
#endif
            
        objval[0] += rtemp*log(rtemp);
      }
    }
    
    objval[0] *= OBJSCAL;

#if DEBUG
    printf ("objval = %e\n",objval[0]);
#endif
  }

  
  if ( numgrdobjnz )
  {
    /* Compute and store the gradient of the f. */


    itemp = 0; 

    for(k=0; k<1; ++k)
    {
      for(j=nlh->p[k]; j<nlh->p[k+1]; ++j)
      {
        grdobjsub[itemp]  = j;
#if DEBUG
        assert(xx[j] > 0);
#endif
        grdobjval[itemp]  = -log(xx[j])-1.0;
                         ++ itemp; 
      }
    }   

    for(k=1; k<nlh->t; ++k)
    {
      if ( nlh->p[k+1]-nlh->p[k]>1 )
      {
        rtemp = 0.0;
        for(j=nlh->p[k]; j<nlh->p[k+1]; ++j)
          rtemp += xx[j];
  
        for(j=nlh->p[k]; j<nlh->p[k+1]; ++j)
        {
          grdobjsub[itemp]  = j;
#if DEBUG
          assert(xx[j] > 0);
#endif
          grdobjval[itemp]  = log(rtemp/xx[j]);
                           ++ itemp; 
        }
      }
    }   

    numgrdobjnz[0] = itemp;

    for(k=0; k<numgrdobjnz[0]; ++k)
      grdobjval[k] *= OBJSCAL;

  }

  if ( conval )
    for(k=0; k<numi; ++k)
      conval[k] = 0.0;

  if ( grdlag )
  {
    /* Compute and store the gradient of the Lagrangian.
     * Note that it is stored as a dense vector.
     */


    for(j=0; j<nlh->n; ++j)
      grdlag[j] = 0.0;

    for(k=0; k<1; ++k)
    {
      for(j=nlh->p[k]; j<nlh->p[k+1]; ++j)
      {
          grdlag[j]  = yo*(-log(xx[j])-1.0);
      }
    }   

    for(k=1; k<nlh->t; ++k)
    {
      if ( nlh->p[k+1]-nlh->p[k]>1 )
      {
        rtemp = 0.0;
        for(j=nlh->p[k]; j<nlh->p[k+1]; ++j)
          rtemp += xx[j];
  
        for(j=nlh->p[k]; j<nlh->p[k+1]; ++j)
        {
            grdlag[j] = yo*log(rtemp/xx[j]);
        }
      }
    }   


    for(j=0; j<nlh->n; ++j)
      grdlag[j] *= OBJSCAL;

#if DEBUG && PRINT_GRDLAG
     for(j=0; j<nlh->n; ++j)
       printf("grdlag[%d] = %e\n",j,grdlag[j]);
#endif
        
  }

  if ( maxnumhesnz )
  {
    /* Compute and store the Hessian of the Lagrangian
     * which in this case is identical to the Hessian
     * of f times yo.
     */

    if ( yo==0.0 )
    {
      if ( numhesnz )
        numhesnz[0] = 0;
    }
    else
    {
      if ( numhesnz )
      {
        numhesnz[0] = nlh->numhesnz;

        if ( maxnumhesnz<nlh->numhesnz )
          return ( 1 );

        /* The diagonal element. */
        l = 0;
        for(j=nlh->p[0]; j<nlh->p[1]; ++j)
        {
          hessubi[l]  = j;
          hessubj[l]  = j;
          hesval[l]   =  -yo/xx[j];
                      ++ l;

        }

        for(k=1; k<nlh->t; ++k)
        {
          if ( nlh->p[k+1]-nlh->p[k]>1)
          {
            double invrtemp;

            rtemp = 0.0;
            for(j=nlh->p[k]; j<nlh->p[k+1]; ++j)
            {
              rtemp += xx[j];
            } 

            invrtemp = 1.0/rtemp;
          
            /* The diagonal element. */
            for(j=nlh->p[k]; j<nlh->p[k+1]; ++j)
            {
              hessubi[l]  = j;
              hessubj[l]  = j;
              /* equivalent to hesval[l]   = yo*(invrtemp - 1.0/xx[j]); */
              hesval[l]   = yo*(xx[j]-rtemp)/(rtemp*xx[j]);
                         ++ l;
                         
              /* The off diagonal elements. */
             for(i=j+1; i<nlh->p[k+1]; ++i)
             {
               hessubi[l]  = i;
               hessubj[l]  = j;
               hesval[l]   = yo*invrtemp;
                          ++ l;
             }
            }
          }
        }

        for(k=0; k<numhesnz[0]; ++k)
          hesval[k] *= OBJSCAL;


        #if DUMPHESSIAN
        {
          FILE *f;

          f = fopen("hessian.txt","wt");
          for(k=0; k<numhesnz[0]; ++k)
            fprintf(f,"%d %d %24.16e\n",hessubi[k],hessubj[k],hesval[k]);

          fclose(f); 
        }
        #endif     
 

#if DEBUG && PRINT_HESVAL
        for(k=0; k<numhesnz[0]; ++k)
          printf("hesval[%d] = %e\n",k,hesval[k]);
#endif
        
      }
    }
  }
  MSK_checkmemtask(nlh->task,__FILE__,__LINE__);

  return ( 0 );
} /* dgoeval */

MSKrescodee MSK_dgoread(MSKtask_t  task,
                        const char *nldatafile,
                        MSKint32t  *numvar,       /* numterms in primal */
                        MSKint32t  *numcon,       /* numvar in primal */
                        MSKint32t  *t,            /* number of constraints in primal*/
                        double     **v,           /* coiefients for terms in primal*/
                        MSKint32t  **p            /* corresponds to number of terms 
                                                     in each constraint in the 
                                                     primal */
                        )
{
  MSKrescodee r=MSK_RES_OK;
  MSKenv_t    env;
  char        buf[MAX_LINE_LENGTH];
  FILE        *f;
  MSKint32t   i;

  MSK_getenv(task,&env);
  v[0] = NULL; p[0] = NULL;
  
  f         = fopen(nldatafile,"rt");
  
  if (f)
  {
    fgets(buf,sizeof(buf),f);
    t[0] = (int) atol(buf);
  }
  else
  {
    printf("Could not open file '%s'\n",nldatafile);
    r = MSK_RES_ERR_FILE_OPEN;
  }
  
  if (r == MSK_RES_OK)
    r = MSK_getnumvar(task,numvar);

  if (r == MSK_RES_OK) 
    r = MSK_getnumcon(task,numcon);

 
  if (r == MSK_RES_OK)
  {
    p[0] = (int*) MSK_calloctask(task,t[0],sizeof(int));
    if (p[0] == NULL)
      r = MSK_RES_ERR_SPACE;
  }
  
    
  if (r == MSK_RES_OK)
  {
    v[0] = (double*) MSK_calloctask(task,numvar[0],sizeof(double));
    if (v[0] == NULL)
      r = MSK_RES_ERR_SPACE;
  }
   
  if (r == MSK_RES_OK)
  {
    for(i=0; i<numvar[0]; ++i)
    {
       fgets(buf,sizeof(buf),f);
       v[0][i] = atof(buf);
    }

    for(i=0; i<t[0]; ++i)
    {
      fgets(buf,sizeof(buf),f);
      p[0][i] = (int) atol(buf);
    }
  }
 
  return ( r );
}
 
MSKrescodee MSK_dgosetup(MSKtask_t task,
                         MSKint32t numvar,
                         MSKint32t numcon,
                         MSKint32t t,
                         double    *v,
                         MSKint32t *p,   
                         dgohand_t *dgoh)
{

  MSKint32t   j,k;
  MSKrescodee r=MSK_RES_OK;
  nlhand_t    *nlh=(nlhand_t *) dgoh;

  nlh[0] = (nlhand_t) MSK_calloctask(task,1,sizeof(nlhandt));
  if ( nlh[0]!=NULL )
  {
    /* set up nonlinear part */
  
    nlh[0]->p    = NULL;
    nlh[0]->n    = numvar;
    nlh[0]->t    = t;
    nlh[0]->task = task;

    nlh[0]->p    = MSK_calloctask(task,nlh[0]->t+1,sizeof(int));
    if (nlh[0]->p!=NULL )
    {
      nlh[0]->p[0] = 0;
      for(k=0; k<nlh[0]->t; ++k)
      {        
        nlh[0]->p[k+1] = nlh[0]->p[k]+p[k];
      }

      for(k=0; k<nlh[0]->t; ++k)
      {
        for(j=nlh[0]->p[k]; j<nlh[0]->p[k+1]; ++j)
        {
          r = MSK_putcj(task,j,OBJSCAL*log(v[j]));
        }
      }  

        
      if ( nlh[0]->p[nlh[0]->t]==nlh[0]->n )
      {
        /*
         * The problem is now defined
         * and the setup can proceed.
         * Next, the number of Hessian non-zeros
         * is computed.
         */

        nlh[0]->numhesnz = nlh[0]->p[1]-nlh[0]->p[0];
        for(k=1; k<nlh[0]->t; ++k)
        {   
          if (( nlh[0]->p[k+1]-nlh[0]->p[k])>1 )  
          {
            /* If only one term in primal constraint, 
               the corresponding value in H is zero. 
             */
            nlh[0]->numhesnz += ((nlh[0]->p[k+1]-nlh[0]->p[k])
                                 * (1+nlh[0]->p[k+1]-nlh[0]->p[k]))/2;
          } 
        }
        printf("Number of Hessian non-zeros: %d\n",nlh[0]->numhesnz);

        MSK_putnlfunc(task,nlh[0],dgostruc,dgoeval);
        r = MSK_putobjsense(task,MSK_OBJECTIVE_SENSE_MAXIMIZE);
      }
      else
      {
        printf("Incorrect function definition.\n");
        printf("n gathered from the task file: %d\n",nlh[0]->n);
        printf("n computed based on p        : %d\n",nlh[0]->p[nlh[0]->t]);
        r = MSK_RES_ERR_UNKNOWN;
      }

    }
    else
      r = MSK_RES_ERR_SPACE;
  }
  else
    r = MSK_RES_ERR_SPACE;
  
  return ( r );
} /* dgosetup */

MSKrescodee MSK_freedgo(MSKtask_t task,
                        dgohand_t *dgoh)
{
  nlhand_t *nlh=(nlhand_t *) dgoh;
 
  if ( nlh[0] )
  {
    /* Free allocated data. */

    MSK_freetask(task,nlh[0]->p);
    MSK_freetask(task,nlh[0]);
    nlh[0] = NULL;
  }
    
  return ( MSK_RES_OK );
}