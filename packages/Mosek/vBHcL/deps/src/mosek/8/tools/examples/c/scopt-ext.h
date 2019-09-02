#ifndef SCOPT_EXT_H
#define SCOPT_EXT_H

/* 
   Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved. 

   File     : scopt-ext.h

 */ 



#include "mosek.h"

#define MSK_OPR_ENT 0
#define MSK_OPR_EXP 1
#define MSK_OPR_LOG 2
#define MSK_OPR_POW 3
#define MSK_OPR_SQRT 4 /* constant for square root operator:  f * sqrt(gx + h) */


typedef void *schand_t;

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
                        schand_t  *sch);
/* Purpose: The function is used to feed a nonlinear
            separable function to MOSEK. The procedure must
            called before MSK_optimize is invoked.
 */


MSKrescodee MSK_scwrite(MSKtask_t task,
                        schand_t  sch,
                        char      filename[]);
/* Purpose: Writes two data files which specifies the problem. One named
            filename.mps and the other is filename.sco.
 */

MSKrescodee MSK_scread(MSKtask_t task,
                       schand_t  *sch,
                       char      filename[]);
/* Purpose: Read the data files created by MSK_scwrite.
 */

MSKrescodee MSK_scend(MSKtask_t task,
                      schand_t  *sch);
/* Purpose: When the nonlinear function data is no longer needed or
            should be changed, then this procedure should be called
            to deallocate previous allocated data in MSK_scbegin.
 */


#endif