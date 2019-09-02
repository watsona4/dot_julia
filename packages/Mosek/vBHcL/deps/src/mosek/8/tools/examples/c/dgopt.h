#ifndef DGOPT_H
#define DGOPT_H

/*
   Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved. 

   File     : dgopt.h
*/

#include "mosek.h"

typedef void *dgohand_t;

MSKrescodee MSK_dgoread(MSKtask_t  task,
                        const char *nldatafile,
                        MSKint32t  *numvar,       /* numterms in primal */
                        MSKint32t  *numcon,       /* numvar in primal */
                        MSKint32t  *t,            /* number of constraints in primal*/
                        double     **v,           /* coiefients for terms in primal*/
                        MSKint32t  **p            /* corresponds to number of terms 
                                                     in each constraint in the 
                                                     primal */
                        );

MSKrescodee MSK_dgosetup(MSKtask_t task,
                         MSKint32t   numvar,
                         MSKint32t   numcon,
                         MSKint32t   t,
                         double    *v,
                         MSKint32t   *p,   
                         dgohand_t *nlh);

MSKrescodee MSK_freedgo(MSKtask_t task,
                        dgohand_t  *nlh);
#endif