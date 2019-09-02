#ifndef EXPOPT_H
#define EXPOPT_H

/*
   Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved. 

   File     : expopt.h
*/

#include "mosek.h"
#include "scopt-ext.h"

typedef void *expopthand_t;


MSKrescodee MSK_expoptread(MSKenv_t   env,
                           const char *filename,
                           MSKint32t  *numcon,  
                           MSKint32t  *numvar,
                           MSKint32t  *numter,
                           MSKidxt    **subi,          /* Which constraint a term belongs to or zero for objective */ 
                           double     **c,             /* Coefficients of terms */
                           MSKidxt    **subk,          /* Term index */
                           MSKidxt    **subj,          /* Variable index */ 
                           double     **akj,           /* akj[i] is coefficient of variable subj[i] in term subk[i] */
                           MSKint32t  *numanz);        /* Length of akj */
/* Purpose:
           Read a geometric optimization problem on the exponential
           optimization form from file filename.  The function allocates the
           arrays subi[0],c,subk[0],subj[0] and akj[0] and it is the users
           responsibility to free them with MSK_free after use.
*/

MSKrescodee MSK_expoptwrite(MSKenv_t   env,
                            const char *filename,
                            MSKint32t  numcon,  
                            MSKint32t  numvar,
                            MSKint32t  numter,
                            MSKidxt    *subi,          
                            double     *c,             
                            MSKidxt    *subk,          
                            MSKidxt    *subj,          
                            double     *akj,           
                            MSKint32t  numanz);

/* Purpose:
           Write an exponential optimization problem to a file.
*/
     
MSKrescodee MSK_expoptsetup(MSKtask_t expopttask,            
                            MSKint32t     solveform,      /* If 0 solver is chosen freely, 1: solve by dual formulation, -1: solve by primal formulation */
                            MSKint32t     numcon,
                            MSKint32t     numvar,
                            MSKint32t     numter,
                            MSKidxt       *subi,
                            double        *c,
                            MSKidxt       *subk,
                            MSKidxt       *subj,
                            double        *akj,
                            MSKint32t     numanz,
                            expopthand_t  *expopthnd);  /* Data structure containing nonlinear information */

/* Purpose: Setup problem in expopttask.  For every call to expoptsetup there
            must be a corresponding call to expoptfree to dealocate data.
*/

MSKrescodee MSK_expoptimize(MSKtask_t    expopttask,
                            MSKprostae   *prosta,
                            MSKsolstae   *solsta,
                            double       *objval,     /* Primal solution value */
                            double       *xx,         /* Primal solution */
                            double       *y,          /* Dual solution. Only given when solving on dual form */ 
                            expopthand_t *expopthnd);

/* Purpose:
            Solve the problem. The primal solution is returned in xx.
*/ 
 
MSKrescodee MSK_expoptfree(MSKtask_t    expopttask,
                           expopthand_t *expopthnd);

/* Purpose:
            Free data allocated by expoptsetup. For every call
            to expoptsetup there must be exactly one call to expoptfree. 
*/

#endif