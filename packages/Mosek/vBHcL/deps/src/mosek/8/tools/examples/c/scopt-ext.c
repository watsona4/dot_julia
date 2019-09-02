/* 
   Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved. 

   File     : scopt-ext.c

 */ 
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "scopt-ext.h"

#define DEBUG 0

typedef struct
        {
          /*
           * Data structure for storing
           * data about the nonlinear
           * functions.
           */

          int    numcon;      /* Number of constraints. */
          int    numvar;      /* Number of variables.   */
          int    numopro;
          int    *opro;
          int    *oprjo;
          double *oprfo;
          double *oprgo;
          double *oprho;

          int    numoprc;
          int    *oprc;
          int    *opric;
          int    *oprjc;
          double *oprfc;
          double *oprgc;
          double *oprhc;

          /* */ 
          int    *ptrc;
          int    *subc;

          /* Work storage employed when evaluating the functions. */ 
          int    *ibuf; 
          int    *zibuf;
          double *zdbuf;

        } nlhandt;

typedef nlhandt *nlhand_t;

static void scgrdobjstruc(nlhand_t nlh,
                          int      *nz,
                          int      *sub)
/* Purpose: Compute number of nonzeros and sparsity
            pattern of the gradient of the objective function.
 */
{
  int j,k,
      *zibuf;

  zibuf = nlh->zibuf;

  #if DEBUG>2
  printf("scgrdobjstruc: begin\n");
  #endif

  if ( nz )
  {
    nz[0] = 0;
    for(k=0; k<nlh->numopro; ++k)
    {
      j = nlh->oprjo[k];

      if ( !zibuf[j] )
      {
        /* A new nonzero in the gradient of the objective has been located. */

        if ( sub )
          sub[nz[0]] = j;

                 ++ nz[0];
        zibuf[j]  = 1;
      }
    }


    /* Zero zibuf again. */
    for(k=0; k<nlh->numopro; ++k)
    {
      j        = nlh->oprjo[k];
      zibuf[j] = 0;
    }
  }

  #if DEBUG>5
  printf("grdnz: %d\n",nz[0]);
  #endif
  #if DEBUG>2
  printf("scgrdobjstruc: end\n");
  #endif

} /* scgrdobjstruc */

static void scgrdconistruc(nlhand_t nlh,
                           int      i,
                           int      *nz,
                           int      *sub)
{
  int j,k,
      *zibuf;

  #if DEBUG>2
  printf("scgrdconistruc: begin\n");
  #endif

  zibuf = nlh->zibuf;

  nz[0] = 0;
  if ( nlh->ptrc )
  {
    for(k=nlh->ptrc[i]; k<nlh->ptrc[i+1]; ++k)
    {
      j = nlh->oprjc[nlh->subc[k]];

      if ( !zibuf[j] )
      {
        /* A new nonzero in the gradient of the ith
           constraint has been located. */

        if ( sub )
          sub[nz[0]] = j;

                 ++ nz[0];
        zibuf[j]  = 1;
      }
    }

    /* Zero zibuf again. */
    for(k=nlh->ptrc[i]; k<nlh->ptrc[i+1]; ++k)
    {
      j        = nlh->oprjc[nlh->subc[k]];
      zibuf[j] = 0;
    }
  }

  #if DEBUG>5
  printf("i: %d nz: %d\n",i,nz[0]);
  #endif
  #if DEBUG>2
  printf("scgrdconistruc: end\n");
  #endif
} /* scgrdconistruc */

static int schesstruc(nlhand_t     nlh,
                      int          yo,
                      int          numycnz,
                      const int *ycsub,
                      int          *nz,
                      int          *sub)
/* Computes the number nonzeros the lower triangular part of
   the Hessian of the Lagrange function and sparsity pattern.
 
   nz: Number of nonzeros in the Hessian of the Lagrange function.
   sub: List of nonzero diagonal elements in the Hessian.
        The separable structure is exploited.
 */
{
  int i,j,k,p,
      *zibuf;

  #if DEBUG>2
  printf("schesstruc: begin\n");
  #endif

  zibuf = nlh->zibuf;

  nz[0] = 0;

  if ( yo )
  {
    /* Information about the objective function should be computed. */
    for(k=0; k<nlh->numopro; ++k)
    {
      j = nlh->oprjo[k];

      if ( !zibuf[j] )
      {
        /* A new nonzero in the gradient has been located. */

        if ( sub )
          sub[nz[0]] = j;

                 ++ nz[0];
        zibuf[j]  = 1;
      }
    }
  }

  if ( nlh->ptrc )
  {
    /* Evaluate the sparsity of the Hessian. Only constraints specified
       by ycsub should be included.
     */
    for(p=0; p<numycnz; ++p)
    {
      i = ycsub[p]; /* Constraint index. */
      for(k=nlh->ptrc[i]; k<nlh->ptrc[i+1]; ++k)
      {
        j = nlh->oprjc[nlh->subc[k]];

        if ( !zibuf[j] )
        {
          /* A new nonzero diagonal element in the Hessian has been located. */
          if ( sub )
            sub[nz[0]] = j;

                 ++ nz[0];
          zibuf[j]  = 1;
        }
      }
    }
  }

  /*
   * Zero work vectors.
   */

  if ( yo )
  {
    for(k=0; k<nlh->numopro; ++k)
    {
      j        = nlh->oprjo[k];
      zibuf[j] = 0;
    }
  }

  if ( nlh->ptrc )
  {
    for(p=0; p<numycnz; ++p)
    {
      i = ycsub[p];
      for(k=nlh->ptrc[i]; k<nlh->ptrc[i+1]; ++k)
      {
        j        = nlh->oprjc[nlh->subc[k]];
        zibuf[j] = 0;
      }
    }
  }

  #if DEBUG>5
  printf("Hessian size: %d\n",nz[0]);
  #endif
  #if DEBUG>2
  printf("schesstruc: end\n");
  #endif

  return ( MSK_RES_OK );
} /* schesstruc */

static int MSKAPI scstruc(void        *nlhandle,
                          int         *numgrdobjnz,
                          int         *grdobjsub,
                          int         i,
                          int         *convali,
                          int         *grdconinz,
                          int         *grdconisub,
                          int          yo,
                          int          numycnz,
                          const int *ycsub,
                          int          maxnumhesnz,
                          int          *numhesnz,
                          int          *hessubi,
                          int          *hessubj)
/* Purpose: Provide information to MOSEK about the
            problem structure and sparsity.
 */
{
  int      k,itemp;
  nlhand_t nlh;

  #if DEBUG>2
  printf("scstruc: begin\n");
  #endif

  nlh = (nlhand_t) nlhandle;

  if ( numgrdobjnz )
    scgrdobjstruc(nlh,numgrdobjnz,grdobjsub);

  if ( convali || grdconinz )
  {
    scgrdconistruc(nlh,i,&itemp,grdconisub);

    if ( convali )
    convali[0] = itemp>0;

    if ( grdconinz )
    grdconinz[0] = itemp;
  }

  if ( numhesnz )
  {
    #if DEBUG>2
    printf("Evaluate Hessian structure yo: %d\n",yo);
    #endif

    schesstruc(nlh,yo,numycnz,ycsub,numhesnz,hessubi);

    if ( numhesnz[0]>maxnumhesnz && hessubi )
    {
      printf("%s(%d): Hessian size error. %d %d\n",__FILE__,__LINE__,numhesnz[0],maxnumhesnz);
      exit(0);
    }

    if ( hessubi )
    {
      /* In this case the Hessian is diagonal matrix. */

      for(k=0; k<numhesnz[0]; ++k)
        hessubj[k] = hessubi[k];
    }
  }

  #if DEBUG>5
  if ( numhesnz )
  {
    printf("Number of Hessian nonzeros: %d\n",numhesnz[0]);
  }
  #endif

  #if DEBUG>2
  printf("scstruc: end\n");
  #endif

  return ( MSK_RES_OK );
} /* scstruc */

static int evalopr(int    opr,
                   double f,
                   double g,
                   double h,
                   int    j,
                   double xj,
                   double *fxj,
                   double *grdfxj,
                   double *hesfxj)
/* Purpose: Evaluates an operator and its derivatives.
     fxj:    Is the function value
     grdfxj: Is the first derivative.
     hexfxj: Is the second derivative.
   Return: A nonzero value if a function could not evaluated. 
 */
{
  double rtemp;

  switch ( opr )
  {
    case MSK_OPR_ENT:
      if ( xj<=0.0 ) 
        return ( 1 );

      if ( fxj )
        fxj[0] = f*xj*log(xj);

      if ( grdfxj )
        grdfxj[0] = f*(1.0+log(xj));

      if ( hesfxj )
        hesfxj[0] = f/xj;
      break;
    case MSK_OPR_EXP:
        rtemp = exp(g*xj+h);

        if ( fxj )
          fxj[0] = f*rtemp;

        if ( grdfxj )
          grdfxj[0] = f*g*rtemp;

        if ( hesfxj )
          hesfxj[0] = f*g*g*rtemp;
      break;
    case MSK_OPR_LOG:
      rtemp = g*xj+h;
      if ( rtemp<=0.0 ) 
        return ( 1 );

      if ( fxj )
        fxj[0] = f*log(rtemp);

      if ( grdfxj )
        grdfxj[0] = (g*f)/(rtemp);

      if ( hesfxj )
        hesfxj[0] = -(f*g*g)/(rtemp*rtemp);
      break;
    case MSK_OPR_POW:
      if ( g==1.0 ) 
      {
        /* This is the linear case.
           We strongly recommend not to put
           linear terms among the nonlinearities. */

        if (fxj)
          fxj[0] = f*(xj+h);

        if ( grdfxj )
          grdfxj[0] = f;

        if ( hesfxj )
           hesfxj[0] = 0.0;
      }
      else
      {
        if (fxj)
          fxj[0] = f*pow(xj+h,g);

        if ( grdfxj )
        {
          if ( xj==0.0 && g<1.0 )
          {
            #if DEBUG
            printf("%s(%d): Hessian evaluation error for variable x%d: %e*(%e+%e)^%e\n",__FILE__,__LINE__,j,f,xj,h,g);
            #endif
            return ( 1 );
          }

          grdfxj[0] = f*g*pow(xj+h,g-1.0);
        }

        if ( hesfxj )
        {
          if ( (xj+h)==0.0 && g<2.0 )
          {
            /* The second order derivative is not defined because 1.0/0.0 has to be evaluated. */

            #if DEBUG
            printf("%s(%d): Hessian evaluation error for variable x%d: %e*(%e+%e)^%e\n",__FILE__,__LINE__,j,f,xj,h,g);
            #endif
            return ( 1 );
          }
          hesfxj[0] = f * g * (g - 1.0) * pow(xj + h, g - 2.0);
        }
      }
      break;
    case MSK_OPR_SQRT: /* handle operator f * sqrt(gx + h) */

      rtemp = g*xj+h;
      if ( rtemp<0.0  || ( rtemp<=0.0 && ( grdfxj || hesfxj ) ) )
      {
        #if DEBUG
        printf("%s(%d): Function evaluation error\n",__FILE__,__LINE__);
        #endif

        return ( 1 );
      }
      
      if ( fxj )
        fxj[0] = f*sqrt(rtemp); /* The function value. */

      if ( grdfxj )
        grdfxj[0] = 0.5*f*g/sqrt(rtemp); /* The gradient. */

      if ( hesfxj )
        hesfxj[0] = -0.25*f*g*g*pow(rtemp,-1.5);
      break;
    default:
      printf("scopt.c: Unknown operator %d\n",opr);
      exit(0);
  }
  
  return ( 0 );
} /* evalopr */

static int scobjeval(nlhand_t        nlh,
                     const double *x,
                     double          *objval,
                     int             *grdnz,
                     int             *grdsub,
                     double          *grdval)
/* Purpose: Compute number objective value and the gradient. */
{
  int    j,k,
         *zibuf;
  int    r = 0;
  double fx,grdfx,
         *zdbuf;

  #if DEBUG>2
  printf("scobjeval: begin\n");
  #endif

  zibuf = nlh->zibuf;
  zdbuf = nlh->zdbuf;

  if ( objval )
    objval[0] = 0.0;

  if ( grdnz )
    grdnz[0] = 0;

  for(k=0; k<nlh->numopro && r==MSK_RES_OK; ++k)
  {
    j = nlh->oprjo[k];

    r = evalopr(nlh->opro[k],nlh->oprfo[k],nlh->oprgo[k],nlh->oprho[k],j,x[j],&fx,&grdfx,NULL);
    if ( r )
    {
      #if DEBUG 
      printf("Failure for variable j: %d\n",j);
      #endif 
    }
    else   
    {
      if ( objval )
        objval[0] += fx;

      if ( grdnz )
      {
        zdbuf[j] += grdfx;

        if ( !zibuf[j] )
        {
          /* A new nonzero in the gradient has been located. */
          grdsub[grdnz[0]]  = j;
          zibuf[j]          = 1;
                           ++ grdnz[0];
        }
      }
    }
  }

  if ( grdnz!=NULL )
  {
    /* Buffers should be zeroed. */
    for(k=0; k<grdnz[0]; ++k)
    {
      j = grdsub[k];

      if ( grdval )
        grdval[k] = zdbuf[j];

      zibuf[j] = 0;
      zdbuf[j] = 0.0;
    }
  }

  #if DEBUG>5
  if ( objval!=NULL )
    printf("objval: %e\n",objval[0]);

  if ( grdnz!=NULL ) 
    printf("grdnz: %d\n",grdnz[0]);

  if ( grdsub && grdval )
  {
    printf("grdobj:");
    for (k=0; k<grdnz[0]; ++k)
      printf(" %e[%d]",grdval[k],grdsub[k]);
    printf("\n");
  }
  #endif

  #if DEBUG>2
  printf("scobjeval: end\n");
  #endif

  return ( r );
} /* scobjeval */

static int scgrdconeval(nlhand_t        nlh,
                        int             i,
                        const double *x,
                        double          *fval,
                        int             grdnz,
                        const int    *grdsub,
                        double          *grdval)
/* Purpose: Compute number value and the gradient of constraint i.
            grdsub[0,...,grdnz-1] tells which values are needed in gradient
            that is required. */
{
  int    r=0,
         j,k,p,gnz,
         *ibuf,*zibuf;
  double fx,grdfx,
         *zdbuf;

  #if DEBUG>2
  printf("scgrdconeval: begin\n");
  #endif

  ibuf  = nlh->ibuf; 
  zibuf = nlh->zibuf;
  zdbuf = nlh->zdbuf;

  if ( fval )
    fval[0] = 0.0;

  if ( nlh->ptrc )
  {
    gnz = 0;
    for(p=nlh->ptrc[i]; p<nlh->ptrc[i+1] && !r; ++p)
    {
      k = nlh->subc[p];
      j = nlh->oprjc[k];

      r = evalopr(nlh->oprc[k],nlh->oprfc[k],nlh->oprgc[k],nlh->oprhc[k],j,x[j],&fx,&grdfx,NULL);

      if ( r )
      {
        #if DEBUG 
        printf("Failure for variable j: %d\n",j);
        #endif 
      }  
      else
      {
        if ( fval )
          fval[0] += fx;

        if ( grdnz>0 )
        {
          zdbuf[j] += grdfx;

          if ( !zibuf[j] )
          {
            /* A new nonzero in the gradient has been located. */

            ibuf[gnz]  = j;
            zibuf[j]   = 1;
                      ++ gnz; 
          }
        }
      }
    }

    if ( grdval!=NULL )
    {
      /* Setup gradient. */
      for(k=0; k<grdnz; ++k)
      {
        j         = grdsub[k];
        grdval[k] = zdbuf[j];
      }
    }

    for(k=0; k<gnz; ++k)
    {
      j        = ibuf[k];
      zibuf[j] = 0;
      zdbuf[j] = 0.0;
    }
  }
  else if ( grdval )
  {
    for(k=0; k<grdnz; ++k)
      grdval[k] = 0.0;
  }


  #if DEBUG>5
  printf("i: %d\n",i);
  if ( fval!=NULL )
    printf("fval: %e\n",fval[0]);

  if ( grdnz )
  {
    printf("grdnz: %d\n", grdnz); 

    if ( grdsub && grdval )
    {
      printf("grd:");
      for(k=0; k<grdnz; ++k) 
        printf(" %e[%d]",grdval[k],grdsub[k]);
      printf("\n");
    }
  }
  #endif

  #if DEBUG>2
  printf("scgrdconeval: end\n");
  #endif

  return ( r );
} /* scgrdconeval */

static int MSKAPI sceval(void            *nlhandle,
                         const double *xx,
                         double          yo,
                         const double *yc,
                         double          *objval,
                         int             *numgrdobjnz,
                         int             *grdobjsub,
                         double          *grdobjval,
                         int             numi,
                         const int    *subi,
                         double          *conval,
                         const int    *grdconptrb,
                         const int    *grdconptre,
                         const int    *grdconsub,
                         double          *grdconval,
                         double          *grdlag,
                         int             maxnumhesnz,
                         int             *numhesnz,
                         int             *hessubi,
                         int             *hessubj,
                         double          *hesval)
/* Purpose: Evalute the nonlinear function and return the
            requested information to MOSEK.
 */
{
  nlhand_t        nlh=(nlhand_t) nlhandle;
  const MSKint32t numcon = nlh->numcon,
                  numvar = nlh->numvar;
  double          fx,grdfx,hesfx;
  int             r=0; 
  int             i,j,k,l,p,
                  *zibuf;
 

  #if DEBUG
  printf("sceval: begin\n");
  #endif

  if ( numhesnz )
    numhesnz[0] = 0;
  
  r      = scobjeval(nlh,xx,objval,numgrdobjnz,grdobjsub,grdobjval);

  for(k=0; k<numi && !r; ++k)
  {
    i = subi[k];
    r = scgrdconeval(nlh,i,xx,
                     conval==NULL    ? NULL : conval+k,
                     grdconsub==NULL ? 0    : grdconptre[k]-grdconptrb[k],
                     grdconsub==NULL ? NULL : grdconsub+grdconptrb[k],
                     grdconval==NULL ? NULL : grdconval+grdconptrb[k]);
  }

  #if DEBUG
  if ( r ) 
    printf("%s(%d): r=%d\n",__FILE__,__LINE__,r);
  #endif


  if ( grdlag && !r )
  {
    /* Compute and store the gradient of the Lagrangian.
     * Note it is stored as a dense vector.
     */

    for(j=0; j<numvar; ++j)
      grdlag[j] = 0.0;

    if ( yo!=0.0 )
    {
      for(k=0; k<nlh->numopro && !r; ++k)
      {
        j = nlh->oprjo[k];
        r = evalopr(nlh->opro[k],nlh->oprfo[k],nlh->oprgo[k],nlh->oprho[k],j,xx[j],NULL,&grdfx,NULL);
        if ( r )
        {
          #if DEBUG
          printf("%s(%d): Function evaluation error for variable j: %d xx: %e\n",__FILE__,__LINE__,j,xx[j]);
          #endif
        }
        else 
          grdlag[j] += yo*grdfx;
      }
    }

    #if DEBUG
    if ( r ) 
      printf("%s(%d): r=%d\n",__FILE__,__LINE__,r);
    #endif

    if ( nlh->ptrc )
    {
      for(l=0; l<numi && !r; ++l)
      {
        i = subi[l];
        for(p=nlh->ptrc[i]; p<nlh->ptrc[i+1] && !r; ++p)
        {
          k = nlh->subc[p];
          j = nlh->oprjc[k];
          r = evalopr(nlh->oprc[k],nlh->oprfc[k],nlh->oprgc[k],nlh->oprhc[k],j,xx[j],NULL,&grdfx,NULL);  
          if ( r )
          {
            #if DEBUG
            printf("%s(%d): Function evaluation error for variable j: %d xx: %e\n",__FILE__,__LINE__,j,xx[j]);
            #endif
          }
          else
            grdlag[j] -= yc[i]*grdfx;
        }
      }
    }
  }

  #if DEBUG
  if ( r ) 
    printf("%s(%d): r=%d\n",__FILE__,__LINE__,r);
  #endif

  if ( maxnumhesnz && !r )
  {
    /* Compute and store the Hessian of the Lagrange function. */

    #if DEBUG & 0
    printf("x: \n");
    for(j=0; j<numvar; ++j)
      printf(" %e\n",xx[j]);

    printf("yc: \n");
    for(i=0; i<numcon; ++i)
      printf(" %e\n",yc[i]);
    #endif 

    zibuf       = nlh->zibuf;
    numhesnz[0] = 0;
    if ( yo!=0.0 )
    {
      for(k=0; k<nlh->numopro && !r; ++k)
      {
        j = nlh->oprjo[k];
        r = evalopr(nlh->opro[k],nlh->oprfo[k],nlh->oprgo[k],nlh->oprho[k],j,xx[j],NULL,NULL,&hesfx);
        if ( r )
        {
          #if DEBUG
          printf("%s(%d): Function evaluation error for variable j: %d xx: %e\n",__FILE__,__LINE__,j,xx[j]);
          #endif
        }
        else
        {
          if ( !zibuf[j] )
          {
                                ++ numhesnz[0];
            zibuf[j]             = numhesnz[0];
            hessubi[zibuf[j]-1]  = j;
            hesval[zibuf[j]-1]   = 0.0;
          }
          hesval[zibuf[j]-1] += yo*hesfx;
        }
      }
    }

    if ( nlh->ptrc )
    {
      for(l=0; l<numi && !r; ++l)
      {
        i = subi[l];
        for(p=nlh->ptrc[i]; p<nlh->ptrc[i+1] && !r; ++p)
        {
          k = nlh->subc[p];
          j = nlh->oprjc[k];
          r = evalopr(nlh->oprc[k],nlh->oprfc[k],nlh->oprgc[k],nlh->oprhc[k],j,xx[j],NULL,NULL,&hesfx);
          if ( r )
          {
            #if DEBUG
            printf("%s(%d): Function evaluation error for variable j: %d xx: %e\n",__FILE__,__LINE__,j,xx[j]);
            #endif
          }
          else
          {
            if ( !zibuf[j] )
            {
                                  ++ numhesnz[0];
              zibuf[j]             = numhesnz[0];
              hesval[zibuf[j]-1]   = 0.0;
              hessubi[zibuf[j]-1]  = j;
            }
            hesval[zibuf[j]-1] -= yc[i]*hesfx;
          }
        }
      }
    }

    if ( numhesnz[0]>maxnumhesnz )
    {
      printf("Hessian evalauation error\n");
      exit(0);
    }

    for(k=0; k<numhesnz[0]; ++k)
    {
      j          = hessubi[k];
      hessubj[k] = j;
      zibuf[j]   = 0;
    }
  }

  #if DEBUG>5
  if ( conval!=NULL )
  {
    printf("conval:");
    for(k=0; k<numi; ++k)
      printf(" %e[%d]",conval[k],subi[k]);
    printf("\n");
  }
  if ( grdlag!=NULL ) 
  {
    printf("grdlag:");
    for(j=0; j<numvar; ++j)
      printf(" %e",grdlag[j]); 
    printf("\n");
  }

  if ( numhesnz!=NULL ) 
  {
    printf("Hessian: "); 
    for(k=0; k<numhesnz[0]; ++k)
      printf(" %e[%d,%d]",hesval[k],hessubi[k],hessubj[k]);
    printf("\n");
  }
  #endif 


  #if DEBUG
  printf("sceval: end\n");
  #endif

  return ( r );
} /* sceval */

MSKrescodee MSK_scbegin(MSKtask_t task,
                        int       numopro,
                        int       *opro,
                        int       *oprjo,
                        double    *oprfo,
                        double    *oprgo,
                        double    *oprho,
                        int       numoprc,
                        int       *oprc,
                        int       *opric,
                        int       *oprjc,
                        double    *oprfc,
                        double    *oprgc,
                        double    *oprhc,
                        schand_t  *sch)
{
  int         itemp,k,p,sum;
  MSKrescodee r=MSK_RES_OK;
  nlhand_t    nlh;

  #if DEBUG
  printf("MSK_scbegin: begin\n");
  #endif

  nlh = (nlhand_t) MSK_calloctask(task,1,sizeof(nlhandt));
  if ( nlh )
  {
    sch[0] = (void *) nlh;

    MSK_getnumcon(task,&nlh->numcon);
    MSK_getnumvar(task,&nlh->numvar);

    nlh->numopro = numopro;
    nlh->opro    = (int *)    MSK_calloctask(task,numopro,sizeof(int));
    nlh->oprjo   = (int *)    MSK_calloctask(task,numopro,sizeof(int));
    nlh->oprfo   = (double *) MSK_calloctask(task,numopro,sizeof(double));
    nlh->oprgo   = (double *) MSK_calloctask(task,numopro,sizeof(double));
    nlh->oprho   = (double *) MSK_calloctask(task,numopro,sizeof(double));

    nlh->numoprc = numoprc;
    nlh->oprc    = (int *)    MSK_calloctask(task,numoprc,sizeof(int));
    nlh->opric   = (int *)    MSK_calloctask(task,numoprc,sizeof(int));
    nlh->oprjc   = (int *)    MSK_calloctask(task,numoprc,sizeof(int));
    nlh->oprfc   = (double *) MSK_calloctask(task,numoprc,sizeof(double));
    nlh->oprgc   = (double *) MSK_calloctask(task,numoprc,sizeof(double));
    nlh->oprhc   = (double *) MSK_calloctask(task,numoprc,sizeof(double));

    if ( ( !numopro || ( nlh->opro && nlh->oprjo && nlh->oprfo && nlh->oprgo && nlh->oprho ) ) &&
         ( !numoprc || ( nlh->oprc && nlh->opric && nlh->oprjc && nlh->oprfc && nlh->oprgc && nlh->oprhc ) )
         )
    {
      p = 0;  
      for(k=0; k<numopro; ++k)
      {
        nlh->opro[p]   = opro[k];
        nlh->oprjo[p]  = oprjo[k];
        nlh->oprfo[p]  = oprfo[k];
        nlh->oprgo[p]  = oprgo[k];
        nlh->oprho[p]  = oprho[k];
        ++p;
      }

      nlh->numopro = p;

      for(k=0; k<numoprc; ++k)
      {
        nlh->oprc[k]  = oprc[k];
        nlh->opric[k] = opric[k];
        nlh->oprjc[k] = oprjc[k];
        nlh->oprfc[k] = oprfc[k];
        nlh->oprgc[k] = oprgc[k];
        nlh->oprhc[k] = oprhc[k];
      }

      #if DEBUG
      /*
       * Check if data is valid.
       */

      for(k=0; k<numopro; ++k)
      {
        if ( oprjo[k]<0 || oprjo[k]>=nlh->numvar )
        {
          printf("oprjo[%d]=%d is invalid.\n",k,oprjo[k]);
          exit(0);
        }
      }

      for(k=0; k<numoprc; ++k)
      {
        if (opric[k]<0 || opric[k]>=nlh->numcon )
        {
          printf("opric[%d]=%d is invalid. numcon: %d\n",k,opric[k],nlh->numcon);
          exit(0);
        }

        if ( oprjc[k]<0 || oprjc[k]>=nlh->numvar )
        {
          printf("oprjc[%d]=%d is invalid.\n",k,oprjc[k]);
          exit(0);
        }
      }
      #endif

      /*
       * Allocate work vectors.
       */

      nlh->ibuf  = (int *)    MSK_calloctask(task,nlh->numvar,sizeof(int));
      nlh->zibuf = (int *)    MSK_calloctask(task,nlh->numvar,sizeof(int));
      nlh->zdbuf = (double *) MSK_calloctask(task,nlh->numvar,sizeof(double));
      if ( numoprc )
      {
        nlh->ptrc = (int *) MSK_calloctask(task,nlh->numcon+1,sizeof(int));
        nlh->subc = (int *) MSK_calloctask(task,numoprc,sizeof(int));
      }

      if ( ( !nlh->numvar || ( nlh->ibuf && nlh->zibuf && nlh->zdbuf ) ) &&
           ( !numoprc || ( nlh->ptrc && nlh->subc ) ) )
      {
        if ( nlh->numcon && numoprc>0 )
        {
          /*
             Setup of ptrc and sub. Afte the setup then 
             1) ptrc[i+1]-ptrc[i]: Is the number of nonlinear terms in the ith constraint.
             2) subc[ptrc[i],...,ptrc[i+1]-1]: List the nonlinear terms in the ith constrint.
           */
       
          for(k=0; k<numoprc; ++k)
            ++ nlh->ptrc[opric[k]];

          sum = 0;
          for(k=0; k<=nlh->numcon; ++k)
          {
            itemp         = nlh->ptrc[k];
            nlh->ptrc[k]  = sum;
            sum          += itemp;
          }

          for(k=0; k<numoprc; ++k)
          {
            nlh->subc[nlh->ptrc[opric[k]]]  = k;
            ++ nlh->ptrc[opric[k]];
          }

          for(k=nlh->numcon; k; --k)
            nlh->ptrc[k] = nlh->ptrc[k-1];

          nlh->ptrc[0] = 0;

          #if DEBUG
          {
            int p;
            for(k=0; k<nlh->numcon; ++k)
            {
              printf("ptrc[%d]: %d subc: \n",k,nlh->ptrc[k]);
              for(p=nlh->ptrc[k]; p<nlh->ptrc[k+1]; ++p)
              printf(" %d",nlh->subc[p]);
              printf("\n");
            }
          }
          #endif
        }
        r = MSK_putnlfunc(task,(void *) nlh,scstruc,sceval);
      }
      else
        r = MSK_RES_ERR_SPACE;
    }
    else
      r = MSK_RES_ERR_SPACE;
  }
  else
    r = MSK_RES_ERR_SPACE;
  
  #if DEBUG
  printf("MSC_begin: end\n");
  #endif

  return ( r );
} /* MSK_scbegin */

MSKrescodee MSK_scwrite(MSKtask_t task,
                        schand_t  sch,
                        char      filename[])
{
  char        *fn;  
  int         k;
  FILE        *f;
  MSKrescodee r=MSK_RES_OK;
  nlhand_t    nlh;
  size_t      l;

  nlh = (nlhand_t) sch;
  l   = strlen(filename);
  fn  = (char*) MSK_calloctask(task,l+5,sizeof(char));
  if ( fn )
  {
    for(l=0; filename[l] && filename[l]!='.'; ++l)
    fn[l] = filename[l];
  
    strcpy(fn+l,".mps");

    r = MSK_writedata(task,fn);
    if ( r==MSK_RES_OK )
    {
      strcpy(fn+l,".sco");

      f = fopen(fn,"wt");
      if ( f )
      {
        printf("Writing: %s\n",fn);

        fprintf(f,"%d\n",nlh->numopro);

        for(k=0; k<nlh->numopro; ++k)
          fprintf(f,"%-8d %-8d %-24.16e %-24.16e %-24.16e\n",
                  nlh->opro[k],
                  nlh->oprjo[k],
                  nlh->oprfo[k],
                  nlh->oprgo[k],
                  nlh->oprho[k]);

        fprintf(f,"%d\n",nlh->numoprc);
        for(k=0; k<nlh->numoprc; ++k)
          fprintf(f,"%-8d %-8d %-8d %-24.16e %-24.16e %-24.16e\n",
                  nlh->oprc[k],
                  nlh->opric[k],
                  nlh->oprjc[k],
                  nlh->oprfc[k],
                  nlh->oprgc[k],
                  nlh->oprhc[k]);
      }
      else
      {
        printf("Could not open file: '%s'\n",filename);
        r = MSK_RES_ERR_FILE_OPEN;
      }
      fclose(f);
    }  
  }
  else
    r = MSK_RES_ERR_SPACE;

  MSK_freetask(task, fn);

  #if DEBUG
  printf("MSK_scwrite: end\n");
  #endif
  
  return ( r );
} /* MSK_scwrite */

MSKrescodee MSK_scread(MSKtask_t task,
                       schand_t  *sch,
                       char      filename[])
{
  char        buffer[1024],fbuf[80],hbuf[80],gbuf[80],
              *fn;
  double      *oprfo=NULL,*oprgo=NULL,*oprho=NULL,*oprfc=NULL,*oprgc=NULL,*oprhc=NULL;
  int         k,p,
              numopro,numoprc,
              *opro=NULL,*oprjo=NULL,*oprc=NULL,*opric=NULL,*oprjc=NULL;
  FILE        *f;
  MSKrescodee r;
  size_t      l;

  #if DEBUG
  printf("MSK_scread: begin\n");
  #endif

  sch[0] = NULL;
  l      = strlen(filename);
  fn     = (char*) MSK_calloctask(task,l+5,sizeof(char));
  if ( fn )
  {
    strcpy(fn, filename);
    for(k=0; fn[k] && fn[k]!='.'; ++k);

    strcpy(fn+k,".mps");

    {
      r = MSK_readdata(task,fn);
      if ( r==MSK_RES_OK )
      {
        strcpy(fn+k,".sco");

        printf("Opening: %s\n",fn); 

        f = fopen(fn,"rt");
        if ( f )
        {
          printf("Reading.\n");

          fgets(buffer,sizeof(buffer),f);
          sscanf(buffer,"%d",&numopro);

          if ( numopro )
          {
            opro  = (int*) MSK_calloctask(task, numopro, sizeof(int));
            oprjo = (int*) MSK_calloctask(task, numopro, sizeof(int));
            oprfo = (double*) MSK_calloctask(task, numopro, sizeof(double));
            oprgo = (double*) MSK_calloctask(task, numopro, sizeof(double));
            oprho = (double*) MSK_calloctask(task, numopro, sizeof(double));
  
            if ( opro && oprjo && oprfo && oprgo && oprho )
            {
              for(k=0; k<numopro; ++k)
              {
                fgets(buffer,sizeof(buffer),f);

                for(p=0; buffer[p]; ++p)
                  if ( buffer[p]==' ' )
                    buffer[p] = '\n';

                sscanf(buffer,"%d %d %s %s %s",
                       opro+k,
                       oprjo+k,
                       fbuf,
                       gbuf,
                       hbuf);

                oprfo[k] = atof(fbuf);
                oprgo[k] = atof(gbuf);
                oprho[k] = atof(hbuf);
              }
            }
            else
              r = MSK_RES_ERR_SPACE;
          }

          
          if ( r==MSK_RES_OK )
          { 
            fgets(buffer,sizeof(buffer),f);
            sscanf(buffer,"%d",&numoprc);
  
            if ( numoprc )
            {
              oprc  = (int*) MSK_calloctask(task,numoprc,sizeof(int));
              opric = (int*) MSK_calloctask(task,numoprc,sizeof(int));
              oprjc = (int*) MSK_calloctask(task,numoprc,sizeof(int));
              oprfc = (double*) MSK_calloctask(task,numoprc,sizeof(double));
              oprgc = (double*) MSK_calloctask(task,numoprc,sizeof(double));
              oprhc = (double*) MSK_calloctask(task,numoprc,sizeof(double));
  
              if ( oprc && oprjc && oprfc && oprgc && oprhc )
              {
                for(k=0; k<numoprc; ++k)
                {
                  fgets(buffer,sizeof(buffer),f);
  
                  for(p=0; buffer[p]; ++p)
                    if ( buffer[p]==' ' )
                      buffer[p] = '\n';
  
                  sscanf(buffer,"%d %d %d %s %s %s",
                         oprc+k,
                         opric+k,
                         oprjc+k,
                         fbuf,
                         gbuf,
                         hbuf);
  
                  oprfc[k] = atof(fbuf);
                  oprgc[k] = atof(gbuf);
                  oprhc[k] = atof(hbuf);
                }
              }
              else
                r = MSK_RES_ERR_SPACE;
            }
            else
              printf("No nonlinear terms in constraints\n");
          }

          fclose(f);
        }
        else
        {
          printf("Could not open file: '%s'\n",fn);
          r = MSK_RES_ERR_FILE_OPEN;
        }
            
        if ( r==MSK_RES_OK )
          r = MSK_scbegin(task,
                          numopro,
                          opro,
                          oprjo,
                          oprfo,
                          oprgo,
                          oprho,
                          numoprc,
                          oprc,
                          opric,
                          oprjc,
                          oprfc,
                          oprgc,
                          oprhc,
                          sch);

        MSK_freetask(task, opro);
        MSK_freetask(task, oprjo);
        MSK_freetask(task, oprfo);
        MSK_freetask(task, oprgo);
        MSK_freetask(task, oprho);

        MSK_freetask(task, oprc);
        MSK_freetask(task, opric);
        MSK_freetask(task, oprjc);
        MSK_freetask(task, oprfc);
        MSK_freetask(task, oprgc);
        MSK_freetask(task, oprhc);
      }
      else
      {
        printf("Could not open file: '%s'\n",filename);
        r = MSK_RES_ERR_FILE_OPEN;
      }
    }
  }
  else
    r = MSK_RES_ERR_SPACE;

  MSK_freetask(task,fn);

  #if DEBUG
  printf("MSK_scread: end r: %d\n",r);
  #endif

  return ( r );
} /* MSK_scread */


MSKrescodee MSK_scend(MSKtask_t task,
                      schand_t  *sch)
/* Purpose: Free all data associated with nlh. */
{
  nlhand_t nlh;
  
  #if DEBUG
  printf("MSK_scend: begin\n");
  #endif

  if ( sch[0] )
  {
    /* Remove nonlinear function data. */
    MSK_putnlfunc(task,NULL,NULL,NULL);

    nlh    = (nlhand_t) sch[0];
    sch[0] = nlh;

    #if DEBUG
    printf("MSK_scend: deallocate\n");
    #endif

    MSK_freetask(task,nlh->opro);
    MSK_freetask(task,nlh->oprjo);
    MSK_freetask(task,nlh->oprfo);
    MSK_freetask(task,nlh->oprgo);
    MSK_freetask(task,nlh->oprho);

    MSK_freetask(task,nlh->oprc);
    MSK_freetask(task,nlh->opric);
    MSK_freetask(task,nlh->oprjc);
    MSK_freetask(task,nlh->oprfc);
    MSK_freetask(task,nlh->oprgc);
    MSK_freetask(task,nlh->oprhc);

    MSK_freetask(task,nlh->ptrc);
    MSK_freetask(task,nlh->subc);
    MSK_freetask(task,nlh->ibuf);
    MSK_freetask(task,nlh->zibuf);
    MSK_freetask(task,nlh->zdbuf);

    MSK_freetask(task,nlh);
  }

  #if DEBUG
  printf("MSK_scend: end\n");
  #endif

  return ( MSK_RES_OK );
} /* MSK_scend */