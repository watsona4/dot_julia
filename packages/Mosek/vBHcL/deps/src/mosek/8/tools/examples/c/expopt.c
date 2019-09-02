/* 
   Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.

   File:      expopt.c

   Purpose:   Solve the exponential optimization problem. 
*/
#define SCALE          1
#define DEBUG          0
#define WRITE_AS_SCOPT 0

#include <math.h>
#include <stdio.h>

#include "dgopt.h"
#include "expopt.h"
 
typedef struct
        {
          
          int solveform;
          MSKint32t numvar;
          void      *nl_data;
          
        } nlhandt;

typedef nlhandt *nlhand_t;

#define MAX_LINE_LENGTH 256 /* max length of a line in data format is 256 */

static int isemptyline(char* text)
{
  for (;text[0] != '\0';text++)
  {
    if (text[0] != ' ' && text[0] != '\f'  && text[0] != '\n' && text[0] != '\t' && text[0] != '\v')
    {
      if (text[0] == '*')
        return 1;
      else
        return 0;
    }
  }
  return 1;
}

static char* fgets0(char *buf,
                    int  s,
                    FILE *f)
{
  size_t   numreadtotal = 0,numread = 0;
  int i = 0;
  char c;
  
  while (i<s-1)
  {
    numread = fread(&c,1,1,f);

    if (numread != 1)
      break;
    
    numreadtotal+= numread;    
    
    if (c != '\r')
      buf[i++] = c;
      
    if (c == '\n')
    {      
      break;
    }     
  }  
  
  buf[i++] = '\0'; 
  
  if (numreadtotal)
    return buf;
  else
    return NULL;  
}

static char* getnextline(char *buf,
                         int  s,
                         FILE *f,
                         int  *line)
{
  char *p;
  int l =0;
  do
  {
    p = fgets0(buf,s,f);
    line[0]++;
  }
  while (p && isemptyline(buf));
  
  if (p == NULL || isemptyline(p))
    return ( NULL );
  else
    return ( p );
}

static int parseint(char *buf,
                    int  *val)
{
  char *end;
  
  val[0] = (int) strtol (buf,&end,10);

  if (isemptyline(end))
    return ( 0 );
  else
    return ( 1 );
}

static int parsedbl(char   *buf,
                    double *val)
{
  char *end;

  val[0] = strtod (buf,&end);

  if (isemptyline(end))
    return ( 0 );
  else
    return ( 1 );    
}

static int parsetriple(char   *buf,
                       int    *val1,
                       int    *val2,
                       double *val3)
{
  char *end;
  
  val1[0] = (int) strtol (buf,&end,10);
  
  if (end[0] != ' ' && end[0] != '\t' && end[0] != '\v')
  { 
    return ( 1 );
  } 

  val2[0] = (int) strtol (end,&end,10);
  
  if (end[0] != ' ' &&  end[0] != '\t' && end[0] != '\v')
  {
    return ( 1 );
  }
   
  val3[0] =  strtod (end,&end);

  if (isemptyline(end))
    return ( 0 );
  else
    return ( 1 );    
}



MSKrescodee
MSK_expoptread(MSKenv_t   env,
               const char *filename,
               MSKint32t  *numcon,  
               MSKint32t  *numvar,
               MSKint32t  *numter,
               MSKidxt    **subi,          /* Which constraint a term belongs to or zero for objective */ 
               double     **c,             /* Coefficients of terms */
               MSKidxt    **subk,          /* Term index */
               MSKidxt    **subj,          /* Variable index */ 
               double     **akj,           /* akj[i] is coefficient of variable subj[i] in term subk[i] */
               MSKint32t  *numanz)         /* Length of akj */
                   
/* Purpose:
           Read a geometric optimization problem on the exponential
           optimization form from file filename.  The function allocates the
           arrays subi[0],c,subk[0],subj[0] and akj[0] and it is the users
           responsibility to free them with MSK_free after use.
 */
{
  MSKrescodee r = MSK_RES_OK;
  char    buf[MAX_LINE_LENGTH];
  char    buf2[MAX_LINE_LENGTH];  
  FILE    *f;
  int     line = 0;
  MSKidxt i;
  long    fpos;
  MSKintt itmp,itmp2;
  double  rtmp;
  
  subi[0] = NULL;
  subj[0] = NULL;
  subk[0] = NULL;  
  akj[0]  = NULL;
  c[0]    = NULL;
  
  f = fopen(filename,"rb");
  
  if (!f)
  {
    printf("Could not open file '%s'\n",filename);
    r = MSK_RES_ERR_FILE_OPEN;
  }
  else
  {
    if (r == MSK_RES_OK)
      getnextline(buf,sizeof(buf),f,&line);
    
    if (r == MSK_RES_OK && (parseint(buf,numcon) != 0))
    {
      printf("Syntax error in '%s' line %d.\n",filename,line);
      r = MSK_RES_ERR_FILE_READ;
    }
    
    if (r == MSK_RES_OK)
      getnextline(buf,sizeof(buf),f,&line);

    if (r == MSK_RES_OK && (parseint(buf,numvar) != 0))
    {
      printf("Syntax error in '%s' line %d.\n",filename,line);
      r = MSK_RES_ERR_FILE_READ;
    }
    
    if (r == MSK_RES_OK && getnextline(buf,sizeof(buf),f,&line) == NULL)
    {
      printf("Syntax error: Unexpected EOF in '%s' line %d.\n",filename,line);
      r = MSK_RES_ERR_FILE_READ;
    } 
   
    if (r == MSK_RES_OK && (parseint(buf,numter) != 0))
    {
      printf("Syntax error in '%s' line %d.\n",filename,line);
      r = MSK_RES_ERR_FILE_READ;
    }   
    
    if (r == MSK_RES_OK)
    {
      c[0] = MSK_callocenv(env,numter[0],sizeof(double));
      if (c[0] == NULL)
        r = MSK_RES_ERR_SPACE;
    }
    
    if (r == MSK_RES_OK)
    {
      subi[0] = MSK_callocenv(env,numter[0],sizeof(double));
      if (subi[0] == NULL)
        r = MSK_RES_ERR_SPACE;
    }
    
    /* read coef for terms */
    for (i=0; r == MSK_RES_OK && i<numter[0] ;++i)
    {
      if (getnextline(buf,sizeof(buf),f,&line) == NULL)
      {
        printf("Syntax error: Unexpected EOF in '%s' line %d.\n",filename,line);
        r = MSK_RES_ERR_FILE_READ;
      }
      
      if (r == MSK_RES_OK && parsedbl(buf,c[0]+i) != 0)
      {
        printf("Syntax error in '%s' line %d.\n",filename,line);
        r = MSK_RES_ERR_FILE_READ;
      }
     
      if (c[0][i] == 0.0)
      {
        printf ("In '%s' line %d: Coeficients with value zero is not allaowed.\n",filename,line);
        r = MSK_RES_ERR_FILE_READ;
      }          
    }
    
    /* read constraint index of terms */
     
    for (i=0;r == MSK_RES_OK && i<numter[0];++i)
    {

      if (getnextline(buf,sizeof(buf),f,&line) == NULL)
      {
        printf("Syntax error: Unexpected EOF in '%s' line %d.\n",filename,line);
        r = MSK_RES_ERR_FILE_READ;
      }

      if (r == MSK_RES_OK && parseint(buf,subi[0]+i) != 0)
      {
        printf("Syntax error on line %d. Constraint index expected.\n",line);
        r = MSK_RES_ERR_FILE_READ;
      }

      if (subi[0][i] > numcon[0])
      {
        printf("The index subi[%d] = %d is to large (%d) in '%s' line %d\n",i,subi[0][i],numcon[0],filename,line);
        r = MSK_RES_ERR_FILE_READ;
      }        
          
    }
    
    /* Estimate number of nz coefficients */
    
    fpos = ftell (f);
 

    numanz[0] = 0;
    itmp2 = line;
    while (r == MSK_RES_OK)
    {
      char* ret;
      
      ret = getnextline(buf,sizeof(buf),f,&itmp2);

      if (!ret)
        break;
            
      if (parsetriple(buf,&itmp,&itmp,&rtmp) == 0)
      {
        numanz[0]++;
      }
      else
      {
        printf("Syntax error on line %d.\n", itmp2);
        r = MSK_RES_ERR_FILE_READ;
      }

    }
    
    fseek (f,fpos,SEEK_SET);

    if (r == MSK_RES_OK)
    {
      akj[0] = MSK_callocenv(env,numanz[0],sizeof(double));
      if (akj[0] == NULL)
        r = MSK_RES_ERR_SPACE;
    }

    if (r == MSK_RES_OK)
    {
      subk[0] = MSK_callocenv(env,numanz[0],sizeof(int));
      if (subk[0]  == NULL)
        r = MSK_RES_ERR_SPACE;
    }

    if (r == MSK_RES_OK)
    {
      subj[0] = MSK_callocenv(env,numanz[0],sizeof(int));
      if (subj[0]  == NULL)
        r = MSK_RES_ERR_SPACE;
    }
    
    /* read coefficients */ 
    for (i=0;i<numanz[0] && r == MSK_RES_OK;++i)
    {
      getnextline(buf,sizeof(buf),f,&line);
      

      if (parsetriple(buf,subk[0] + i,subj[0] + i,akj[0] + i) != 0)
      { 
        printf("Syntax error on line %d.\n",line);
        r = MSK_RES_ERR_FILE_READ;
      }

      if (subk[0][i] >= numter[0])
      {
        printf("The index subk[%d] = %d is to large in line %d\n",i,subk[0][i],line);
        r = MSK_RES_ERR_FILE_READ;
      }

      if (subj[0][i] >= numvar[0])
      {
        printf("The index subj[%d] = %d is to large (> %d) in line %d\n",i,subj[0][i],numvar[0],line);
        r = MSK_RES_ERR_FILE_READ;
      }           
            
    }
      
  }  
  return ( r );
}

MSKrescodee
MSK_expoptwrite(MSKenv_t   env,
                const char *filename,
                MSKint32t  numcon,  
                MSKint32t  numvar,
                MSKint32t  numter,
                MSKidxt    *subi,          
                double     *c,             
                MSKidxt    *subk,          
                MSKidxt    *subj,          
                double     *akj,           
                MSKint32t  numanz)
{
  MSKrescodee r = MSK_RES_OK;
  FILE        *f;
  MSKint32t   i;
  
  f = fopen(filename,"wt");

  if (f)
  {
    fprintf(f,"%d\n",numcon);
    fprintf(f,"%d\n",numvar);
    fprintf(f,"%d\n",numter);

    for (i=0;i<numter;++i)
      fprintf(f,"%e\n",c[i]);

    for (i=0;i<numter;++i)
      fprintf(f,"%d\n",subi[i]);

    for (i=0;i<numanz;++i)
      fprintf(f,"%d %d %e\n",subk[i],subj[i],akj[i]);
  }
  else
  {
    printf("Could not open file '%s'\n",filename);
    r = MSK_RES_ERR_FILE_OPEN;
  }
    
  fclose(f);
  
  return ( r );
}
      
MSKrescodee 
MSK_expoptsetup(MSKtask_t     expopttask,            
                MSKint32t     solveform,      /* If 1 solve by dual formulation */
                MSKint32t     numcon,
                MSKint32t     numvar,
                MSKint32t     numter,
                MSKidxt       *subi,
                double        *c,
                MSKidxt       *subk,
                MSKidxt       *subj,
                double        *akj,
                MSKint32t     numanz,
                expopthand_t  *expopthnd)  /* Data structure containing nonlinear information */

/* Purpose: Setup problem in expopttask.  For every call to expoptsetup there
            must be a corresponding call to expoptfree to dealocate data.
  */
{
  MSKrescodee
    r = MSK_RES_OK;
  
#if DEBUG > 0
  printf ("**numvar = %d\n",numvar);
  printf ("**numcon = %d\n",numcon);
  printf ("**numter = %d\n",numter);
#endif
  
  expopthnd[0] = (expopthand_t) MSK_calloctask(expopttask,1,sizeof(nlhandt));
    
  if ( expopthnd[0] ) 
  {
    MSKint32t   i,k,itmp,itmp2;
    MSKint32t numobjterm,numconterm,*nter_per_con = NULL;
    MSKint32t *opro = NULL,*oprjo = NULL;
    double    *oprfo = NULL,*oprgo = NULL,*oprho = NULL;
    MSKint32t numopro,numoprc,*oprc = NULL,*opric = NULL,*oprjc = NULL,*ibuf = NULL;
    double    *oprfc = NULL,*oprgc = NULL,*oprhc = NULL,*rbuf = NULL;
    nlhand_t  nlh=expopthnd[0];

    nlh->solveform = solveform; 
    nlh->numvar    = numvar;
    nlh->nl_data   = NULL;

    /* clear expopttask */
    {
      MSKidxt *delsub = NULL;
      MSKintt delsublen;
      if (r == MSK_RES_OK)
        r = MSK_putnlfunc(expopttask,NULL,NULL,NULL);
      if (r == MSK_RES_OK)
        r = MSK_getnumvar(expopttask,&itmp);

      if (r == MSK_RES_OK)
        r = MSK_getnumcon(expopttask,&itmp2);
    
      delsublen = itmp<itmp2 ? itmp2:itmp;

      if (delsublen)
      {
      if (r == MSK_RES_OK)
      {
        delsub = MSK_calloctask(expopttask,delsublen,sizeof(MSKidxt));
        if (delsub == NULL)
          r = MSK_RES_ERR_SPACE;
      }

      for (i=0;i<delsublen && r == MSK_RES_OK;++i)
        delsub[i]=i;
      
      if (r == MSK_RES_OK)
        r = MSK_removevars(expopttask,itmp,delsub);

      if (r == MSK_RES_OK)
        r = MSK_removecons(expopttask,itmp2,delsub); 

      MSK_freetask(expopttask,delsub);
      }
    }

    for (i=0;i<numter && r == MSK_RES_OK;++i)
    {
      if (subi[i] > numcon)
      {
        printf("The index subi[%d] = %d is to large\n",i,subi[i]);
        r = MSK_RES_ERR_INDEX_IS_TOO_LARGE;
      }
     
      if (subi[i] < 0 && r == MSK_RES_OK)
      {
        printf("The index subi[%d] = %d is negative\n",i,subi[i]);
        r = MSK_RES_ERR_INDEX_IS_TOO_SMALL;
      }    
    }

    for (i=0;i<numanz;++i && r == MSK_RES_OK)
    {
      if (subj[i] >= numvar)
      {
        printf("The index subj[%d] = %d is to large\n",i,subj[i]);
        r = MSK_RES_ERR_INDEX_IS_TOO_LARGE;
      }

      if (subj[i] < 0 && r == MSK_RES_OK)
      {
        printf("The index subj[%d] = %d is negative\n",i,subj[i]);
        r = MSK_RES_ERR_INDEX_IS_TOO_SMALL;
      }  
    }

    for (i=0;i<numter && r == MSK_RES_OK;++i)
    {
      if (c[i] <= 0.0)
      {
        printf ("The coefficient c[%d] <= 0. Only positive coefficients allowed\n",i);
        r = MSK_RES_ERR_UNKNOWN;
      }
    }
    
    numobjterm = 0;
    for (i=0;i<numter;++i)
      if (subi[i] == 0)
        ++numobjterm;
    
    if (r == MSK_RES_OK)
    {
      rbuf = MSK_calloctask(expopttask,numvar+1,sizeof(double));
      if (rbuf == NULL)
        r = MSK_RES_ERR_SPACE;
    }
    
    if (r == MSK_RES_OK)
    {
        ibuf = MSK_calloctask(expopttask,numvar+1,sizeof(double));
        if (ibuf == NULL)
          r = MSK_RES_ERR_SPACE;
    }    

    for (i=0;i<numvar && r == MSK_RES_OK;++i)
      ibuf[i] = 0;

    for (i=0;i<numanz && r == MSK_RES_OK;++i)
      if (akj[i] < 0.0)
        ibuf[subj[i]] = 1;

    for (i=0;i<numvar && r == MSK_RES_OK;++i)
      if (!ibuf[i])
      {
        printf("Warning: The variable with index '%d' has only positive coefficients akj.\n The problem is possibly ill-posed.\n.\n",i);      
      }

    for (i=0;i<numvar && r == MSK_RES_OK;++i)
      ibuf[i] = 0;

    for (i=0;i<numanz && r == MSK_RES_OK;++i)
      if (akj[i] > 0.0)
        ibuf[subj[i]] = 1;

    for (i=0;i<numvar && r == MSK_RES_OK;++i)
      if (!ibuf[i])
      {
        printf("Warning: The variable with index '%d' has only negative coefficients akj.\n The problem is possibly ill-posed.\n",i);      
      }
    
    MSK_checkmemtask(expopttask,__FILE__,__LINE__);

    /* Sort subk,subj,akj increasingly according to subk */

    if (r == MSK_RES_OK)
    {
      MSKintt *displist = NULL;
      MSKidxt *subk_sorted = NULL,*subj_sorted = NULL;
      double *akj_sorted = NULL;   
      
      if (r == MSK_RES_OK)
      {
        displist = (MSKintt*) MSK_calloctask(expopttask,numter+1,sizeof(MSKintt));
        if (displist == NULL)
          r = MSK_RES_ERR_SPACE;
      }

      if (r == MSK_RES_OK)
      {
        subk_sorted = (MSKidxt*) MSK_calloctask(expopttask,numanz,sizeof(MSKidxt));
        if (subk_sorted == NULL)
          r = MSK_RES_ERR_SPACE;
      }

      if (r == MSK_RES_OK)
      {
        subj_sorted = (MSKidxt*) MSK_calloctask(expopttask,numanz,sizeof(MSKidxt));
        if (subj_sorted == NULL)
          r = MSK_RES_ERR_SPACE;
      }

      if (r == MSK_RES_OK)
      {
        akj_sorted = (double*) MSK_calloctask(expopttask,numanz,sizeof(double));
        if (akj_sorted == NULL)
          r = MSK_RES_ERR_SPACE;
      }
      
      if (r == MSK_RES_OK)
      {
        for (i=0;i<numter+1;++i)
          displist[i] = 0;
        
        for (i=0;i<numanz;++i)
          displist[subk[i]+1]++;
        
        for (i=0;i<numter-1;++i)
          displist[i+1] = displist[i] + displist[i+1];  
        
        for (i=0;i<numanz;++i)
        {
        int pos = displist[subk[i]]++;
        subk_sorted[pos] = subk[i];
        subj_sorted[pos] = subj[i];
        akj_sorted[pos]  = akj[i];
        }
        
        subk = subk_sorted;
        subj = subj_sorted;
        akj  = akj_sorted;
      }

      /* Detect duplicates in subj*/ 
      itmp = 0;
      for (i=0;i<numvar;++i)
        ibuf[i] = 0;    
      
      while (itmp < numanz && r == MSK_RES_OK)
      {
        MSKidxt curterm = subk[itmp],begin;
           
        begin = itmp; 
        while ((itmp < numanz) && (subk[itmp] == curterm) &&  r == MSK_RES_OK)
        {
          if (ibuf[subj[itmp]]++)
          {
            printf ("Duplicate variable index in term '%d'. For a given term only one variable index subj[k] is allowed.\n",curterm);
            r = MSK_RES_ERR_UNKNOWN;
          }   
          itmp++;
        }
        
        itmp = begin;

        while ((itmp < numanz) && (subk[itmp] == curterm) &&  r == MSK_RES_OK)
        {
          ibuf[subj[itmp]] = 0;
          itmp++;
        }
      }
      
      MSK_freetask(expopttask,displist);
    } 
    
    if (solveform >=0)  /* If the dual formulation was chosen */
    {
      MSKidxt *p = NULL,*displist = NULL,*pos = NULL;
      double  *v = NULL;
      if (r == MSK_RES_OK)
      {
        p = MSK_calloctask(expopttask,numcon+1,sizeof(MSKidxt));
        if (p == NULL)
          r = MSK_RES_ERR_SPACE;
      }

      if (r == MSK_RES_OK)
      {
        displist = MSK_calloctask(expopttask,numcon+1,sizeof(MSKidxt));
        if (displist == NULL)
          r = MSK_RES_ERR_SPACE;
      }

      if (r == MSK_RES_OK)
      {
        pos = MSK_calloctask(expopttask,numter,sizeof(MSKidxt));
        if (pos == NULL)
          r = MSK_RES_ERR_SPACE;
      }

      if (r == MSK_RES_OK)
      {
        v = MSK_calloctask(expopttask,numter,sizeof(double));
        if (pos == NULL)
          r = MSK_RES_ERR_SPACE;
      }

      if (r == MSK_RES_OK)
        r = MSK_appendvars(expopttask,numter);
      
      if (r == MSK_RES_OK)
        r = MSK_appendcons(expopttask,numvar+1);
      
      if (r == MSK_RES_OK)
      {      
        /* Count number of therm in each constraint */
        for (i=0;i<numcon+1;++i)
          p[i]=0;
        
        for (i=0;i<numter;++i)
          p[subi[i]]+=1;
        
        /* Find order pos of subi sorted increasingly */
       
        displist[0] = 0;
        for (i=1;i<numcon+1 && r == MSK_RES_OK;++i)
          displist[i]=displist[i-1] + p[i-1];
        
        for (i=0;i<numter && r == MSK_RES_OK;++i)
          pos[i] = displist[subi[i]]++;
        
        for (i=0;i<numter && r == MSK_RES_OK;++i)
          v[pos[i]] = c[i];
       
        itmp=0;
      }
      
      while (itmp < numanz && r == MSK_RES_OK)
      {
        MSKidxt curterm = subk[itmp];
        MSKintt nz =0;
        while ((itmp < numanz) && (subk[itmp] == curterm) )
        {
          ibuf[nz] = subj[itmp]; 
          rbuf[nz] = akj[itmp];
          nz++;
          itmp++;
        }

        if (subi[curterm] == 0 && r == MSK_RES_OK)  /* in objective */
        {
          ibuf[nz] = numvar;
          rbuf[nz] = 1.0;
          nz++;
        }
        
        if (r == MSK_RES_OK)
          r = MSK_putacol(expopttask,pos[curterm],nz,ibuf,rbuf);   
      }
      
      for (i=0;i<numter && r == MSK_RES_OK;++i)
        r = MSK_putvarbound(expopttask,i,MSK_BK_LO,0,MSK_INFINITY);

      for (i=0;i<numvar && r == MSK_RES_OK;++i)
        r = MSK_putconbound(expopttask,i,MSK_BK_FX,0,0);

      if (r == MSK_RES_OK)
        r = MSK_putconbound(expopttask,numvar,MSK_BK_FX,1.0,1.0);
     
  #if DEBUG > 0
      /* write linear part */
      MSK_putintparam(expopttask,MSK_IPAR_WRITE_GENERIC_NAMES,MSK_ON);
      MSK_writedata(expopttask,"lp_part_dual_formulation.lp");
  #endif
      
      if (r == MSK_RES_OK)
        r = MSK_dgosetup(expopttask,
                         numter,
                         numvar,
                         numcon+1,
                         v,
                         p,                         
                         &(nlh->nl_data));

      MSK_freetask(expopttask,p);
      MSK_freetask(expopttask,displist);
      MSK_freetask(expopttask,pos);
      MSK_freetask(expopttask,v);   
    }
    else
    { 
      if (r == MSK_RES_OK)
      {
        opro = MSK_calloctask(expopttask,numobjterm,sizeof(MSKintt));
        if (opro == NULL)
          r = MSK_RES_ERR_SPACE;
      }
      
      if (r == MSK_RES_OK)
      {
        oprjo = MSK_calloctask(expopttask,numobjterm,sizeof(double));
        if (oprjo == NULL)
        r = MSK_RES_ERR_SPACE;
      }
      
      if (r == MSK_RES_OK)
      {
        oprfo = MSK_calloctask(expopttask,numobjterm,sizeof(double));
        if (oprfo == NULL)
          r = MSK_RES_ERR_SPACE;
      }
      
      if (r == MSK_RES_OK)
      {
        oprgo = MSK_calloctask(expopttask,numobjterm,sizeof(double));
        if (oprgo == NULL)
          r = MSK_RES_ERR_SPACE;
      }
      
      if (r == MSK_RES_OK)
      {
        oprho = MSK_calloctask(expopttask,numobjterm,sizeof(double));
        if (oprho == NULL)
          r = MSK_RES_ERR_SPACE;  
      }

      if (r == MSK_RES_OK)
      {
        nter_per_con = MSK_calloctask(expopttask,numcon+1,sizeof(MSKintt));
        if (nter_per_con == NULL)
          r = MSK_RES_ERR_SPACE;  
      }
       
      MSK_checkmemtask(expopttask,__FILE__,__LINE__);

      
      if (r == MSK_RES_OK)
      {
      
        for (i=0;i<numcon+1;++i)
          nter_per_con[i] = 0;
        
        /* Setup nonlinear objective */

        for(i=0;i<numter;++i)
          nter_per_con[subi[i]]++;

      
        for(i=0,k=0;i<numter && r == MSK_RES_OK;++i)
        {
          if (subi[i] == 0)
          {
            oprho[k] = 0;
            oprgo[k] = 1.0;
            oprfo[k] = 1.0;          
            oprjo[k] = numvar + i;
            opro[k]  = MSK_OPR_EXP;
            ++k;
          }
        }
      }    
      
      numopro = numobjterm;      
      numconterm = numter - numobjterm; 
      
      if (r == MSK_RES_OK)
      {
        oprc = MSK_calloctask(expopttask,numconterm,sizeof(MSKintt));
        opric = MSK_calloctask(expopttask,numconterm,sizeof(double));
        oprjc = MSK_calloctask(expopttask,numconterm,sizeof(double));
        oprfc = MSK_calloctask(expopttask,numconterm,sizeof(double));
        oprgc = MSK_calloctask(expopttask,numconterm,sizeof(double));
        oprhc = MSK_calloctask(expopttask,numconterm,sizeof(double));
      }

      if (oprc == NULL &&
          opric == NULL &&
          oprjc == NULL &&
          oprfc == NULL &&
          oprgc == NULL &&
          oprhc == NULL)
        r = MSK_RES_ERR_SPACE;     
     
      if ( r == MSK_RES_OK )
      {
        for(i=0,k=0;i<numter && r == MSK_RES_OK;++i)
        {
          if ((subi[i] != 0) && (nter_per_con[subi[i]] > 1))
          {
            oprc[k]  = MSK_OPR_EXP;
            opric[k] = subi[i] -1; 
            oprjc[k] = numvar + i;
            oprfc[k] = 1.0;     
            oprgc[k] = 1.0;
            oprhc[k] = 0.0;
            k++;
          }
        }
        numoprc = k;
      }    

      if (r == MSK_RES_OK)
        r = MSK_appendvars(expopttask,numvar + numter);
      
      if (r == MSK_RES_OK)
        r = MSK_appendcons(expopttask,numcon + numter);

    
      for (i=0;i<numcon && r == MSK_RES_OK;++i)
      {     
        r = MSK_putconbound(expopttask,i,MSK_BK_UP,-MSK_INFINITY,1);    
      }

      for (i=numcon;i<numcon+numter && r == MSK_RES_OK;++i)
      {
        if ((nter_per_con[subi[i-numcon]]) > 1 || (subi[i-numcon] ==0)) 
        {
          r = MSK_putconbound(expopttask,i,MSK_BK_FX,-log(c[i-numcon]),-log(c[i-numcon]));
        }
        else
        {
          r = MSK_putconbound(expopttask,i,MSK_BK_UP,-MSK_INFINITY,-log(c[i-numcon]));
        }
      }

      for (i=0;i<numvar && r == MSK_RES_OK;++i)
      {
        r = MSK_putvarbound(expopttask,i,MSK_BK_FR,-MSK_INFINITY,MSK_INFINITY);
      }

      for (i=numvar;i<numvar+numter && r == MSK_RES_OK;++i)
      {
        r = MSK_putvarbound(expopttask,i,MSK_BK_FR,-MSK_INFINITY,MSK_INFINITY);
      }
      
      MSK_checkmemtask(expopttask,__FILE__,__LINE__);
      
      itmp=0;
      {
        MSKidxt termindex;

        for (termindex=0;termindex<numter;++termindex)
        {
          if (subk[itmp] != termindex)
          {
            MSKintt nz =0;
            ibuf[nz] = numvar + termindex;  /* add v_t */
            rbuf[nz] = -1.0;
            nz++;

            if (r == MSK_RES_OK)
              r = MSK_putarow(expopttask,termindex+numcon,nz,ibuf,rbuf);
            
            if (r == MSK_RES_OK)
              r = MSK_putconbound(expopttask,termindex+numcon,MSK_BK_FX,-log(c[termindex]),-log(c[termindex]));
          }
          else
          {
            MSKintt nz =0;
            
            while ((itmp < numanz) && (subk[itmp] == termindex))
            {
              ibuf[nz] = subj[itmp]; 
              rbuf[nz] = akj[itmp];
              nz++;
              itmp++;
            }
            
            if ((nter_per_con[subi[termindex]] > 1) || subi[termindex] == 0)
            {
              ibuf[nz] = numvar + termindex;  /* add v_t */
              rbuf[nz] = -1.0;
              nz++;

              if (r == MSK_RES_OK)
                r = MSK_putconbound(expopttask,termindex+numcon,MSK_BK_FX,-log(c[termindex]),-log(c[termindex]));
            }
            else
            {
              if (r == MSK_RES_OK)
                r = MSK_putconbound(expopttask,termindex+numcon,MSK_BK_UP,-MSK_INFINITY,-log(c[termindex]));
            }
            
            if (r == MSK_RES_OK)
              r = MSK_putarow(expopttask,termindex+numcon,nz,ibuf,rbuf);
          }
        }
      }
    
        
         
      MSK_checkmemtask(expopttask,__FILE__,__LINE__);

      
      if (r == MSK_RES_OK)
        r = MSK_scbegin(expopttask,
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
                        &(nlh->nl_data));
      

      if (r == MSK_RES_OK)
        r = MSK_putobjsense(expopttask,
                            MSK_OBJECTIVE_SENSE_MINIMIZE);
     
      MSK_checkmemtask(expopttask,__FILE__,__LINE__);

  #if WRITE_AS_SCOPT
      MSK_putintparam(expopttask,
                      MSK_IPAR_WRITE_GENERIC_NAMES,
                      MSK_ON);
        
      MSK_scwrite(expopttask,nlh->nl_data,"scoptp");
  #endif
      
      MSK_freetask(expopttask,opro);
      MSK_freetask(expopttask,oprjo);
      MSK_freetask(expopttask,oprfo);
      MSK_freetask(expopttask,oprgo);
      MSK_freetask(expopttask,oprho);
      MSK_freetask(expopttask,oprc);
      MSK_freetask(expopttask,oprjc);
      MSK_freetask(expopttask,opric);
      MSK_freetask(expopttask,oprfc);
      MSK_freetask(expopttask,oprgc);
      MSK_freetask(expopttask,oprhc);
    }
    
    MSK_freetask(expopttask,rbuf);
    MSK_freetask(expopttask,ibuf);
    MSK_freetask(expopttask,subk);
    MSK_freetask(expopttask,subj);
    MSK_freetask(expopttask,akj);
    MSK_freetask(expopttask,nter_per_con);
  }
  else
    r =MSK_RES_ERR_SPACE;
    
  return ( r );
} /* MSK_expoptsetup*/


MSKrescodee
MSK_expoptimize(MSKtask_t    expopttask,
                MSKprostae   *prosta,
                MSKsolstae   *solsta,
                double       *objval,     /* Primal solution value */
                double       *xx,         /* Primal solution */
                double       *y,          /* Dual solution, this is ONLY supplied when solving on dual form */ 
                expopthand_t *expopthnd)

     /* Purpose:
                Solve the problem. The primal solution is returned in xx.
     */ 
{
  MSKrescodee
    r = MSK_RES_OK;
  nlhand_t         nlh;
  MSKidxt          i;
  nlh = (nlhand_t) expopthnd[0];



#if DEBUG > 0
  /* write linear part */
  MSK_putintparam(expopttask,MSK_IPAR_WRITE_GENERIC_NAMES,MSK_ON);
  MSK_writedata(expopttask,"lp_part_dual_formulation.lp");
#endif

    
  if (nlh->solveform == 1 )
  {
    MSK_echotask(expopttask,MSK_STREAM_MSG,"* Solving exponential optimization problem on dual form. *\n");
    MSK_echotask(expopttask,MSK_STREAM_MSG,"* The following log information refers to the solution of the dual problem. *\n");
  }
  else
  {
    MSK_echotask(expopttask,MSK_STREAM_MSG,"* Solving exponential optimization problem on primal form. *\n");
  }
  
  if (r == MSK_RES_OK)
  {      
    r = MSK_optimize(expopttask);
  }
  
  if (r == MSK_RES_OK)
    r =  MSK_getsolution (
                          expopttask,
                          MSK_SOL_ITR,
                          prosta, 
                          solsta, 
                          NULL, 
                          NULL, 
                          NULL, 
                          NULL, 
                          NULL, 
                          NULL, 
                          NULL,
                          NULL,
                          NULL,
                          NULL,
                          NULL);
  if (r == MSK_RES_OK)
    printf ("solsta = %d, prosta = %d\n", (int)*solsta,(int)*prosta);

  if ( r!=MSK_RES_OK )
  {
    MSK_echotask(expopttask,MSK_STREAM_MSG, "Return code from optimize - %d\n",r);
  }

  MSK_solutionsummary(expopttask,MSK_STREAM_MSG);
     
#if DEBUG > 0
  MSK_solutionsummary(expopttask,MSK_STREAM_MSG);
  MSK_writesolution(expopttask,
                    MSK_SOL_ITR,
                    "expoptsol.itr");
#endif
  if (nlh->solveform == 1)
  {
    int numvar_dual;
    /* transform to primal solution */
    MSK_echotask(expopttask,MSK_STREAM_MSG,"* End solution on dual form. *\n");
    MSK_echotask(expopttask,MSK_STREAM_MSG,"Transforming to primal solution.\n");
    
    if (r == MSK_RES_OK)
      r = MSK_getsolutionslice(expopttask,
                               MSK_SOL_ITR,
                               MSK_SOL_ITEM_Y,
                               0,
                               nlh->numvar,
                               xx
                               );

    if (r == MSK_RES_OK)
      r = MSK_getprimalobj(expopttask,MSK_SOL_ITR,objval);

    objval[0] =  exp(objval[0]);

    for (i=0;i<nlh->numvar;++i)
      xx[i] = -xx[i];

    /* Get dual sol vars */

    if (r == MSK_RES_OK)
      r = MSK_getnumvar(expopttask,&numvar_dual);
    
    if (r == MSK_RES_OK)
      r = MSK_getsolutionslice(expopttask,
                               MSK_SOL_ITR,
                               MSK_SOL_ITEM_XX,
                               0,
                               numvar_dual,
                               y
                               );

  }
  else
  {
  if (r == MSK_RES_OK)
    r = MSK_getsolutionslice(expopttask,
                             MSK_SOL_ITR,
                             MSK_SOL_ITEM_XX,
                             0,
                             nlh->numvar,
                             xx
                             );

  if (r == MSK_RES_OK)
    r = MSK_getprimalobj(expopttask,MSK_SOL_ITR,objval);
  }
  
  return ( r );
}

MSKrescodee MSK_expoptfree(MSKtask_t    expopttask,
                           expopthand_t *expopthnd)
{
  /* Purpose: Free data allocated by expoptsetup. For every call
              to expoptsetup there must be exactly one call to expoptfree. 
   */
  MSKrescodee r=MSK_RES_OK;
  nlhand_t    *nlh=(nlhand_t *) expopthnd;

  if ( nlh[0]!=NULL )
  {
    if ( nlh[0]->nl_data != NULL)
    { 
      if ( nlh[0]->solveform<0 )
        r = MSK_scend(expopttask,&(nlh[0]->nl_data));
      else
        r = MSK_freedgo(expopttask,&(nlh[0]->nl_data));
    }

    MSK_freetask(expopttask,nlh[0]);
    nlh[0] = NULL;
  }
  
  return ( r );
}