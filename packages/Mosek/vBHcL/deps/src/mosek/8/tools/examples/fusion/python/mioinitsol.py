##
#    Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.
#
#    File:    mioinitsol.py
#
#    Purpose:  Demonstrates how to solve a small mixed
#              integer linear optimization problem
#              providing an initial feasible solution.
##
import sys
from mosek.fusion import *

def main(args):
    c = [7.0, 10.0, 1.0, 5.0]

    with Model('mioinitsol') as M:

        n = 4

        x = M.variable('x', n, Domain.integral(Domain.greaterThan(0.0)))

        M.constraint(Expr.sum(x), Domain.lessThan(2.5))

        # Set max solution time
        M.setSolverParam('mioMaxTime', 60.0)
        # Set max relative gap (to its default value)
        M.setSolverParam('mioTolRelGap', 1e-4)
        # Set max absolute gap (to its default value)
        M.setSolverParam('mioTolAbsGap', 0.0)

        # Set the objective function to (c^T * x)
        M.objective('obj', ObjectiveSense.Maximize, Expr.dot(c, x))

        init_sol = [0.0, 2.0, 0.0, 0.0]
        x.setLevel(init_sol)

        # Solve the problem
        M.solve()

        # Get the solution values
        ss = M.getPrimalSolutionStatus()
        print(ss)
        sol = x.level()
        print('x = ', sol)
        print("MIP rel gap = %.2f (%f)" % (M.getSolverDoubleInfo(
            "mioObjRelGap"), M.getSolverDoubleInfo("mioObjAbsGap")))

if __name__ == '__main__':
    main(sys.argv[1:])