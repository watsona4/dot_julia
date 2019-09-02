##
# Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.
#
# File:      TrafficNetworkModel.py
#
# Purpose:   Demonstrates a traffic network problem as a conic quadratic problem.
#
# Source:    Robert Fourer, "Convexity Checking in Large-Scale Optimization",
#            OR 53 --- Nottingham 6-8 September 2011.
#
# The problem:
#            Given a directed graph representing a traffic network
#            with one source and one sink, we have for each arc an
#            associated capacity, base travel time and a
#            sensitivity. Travel time along a specific arc increases
#            as the flow approaches the capacity.
#
#            Given a fixed inflow we now wish to find the
#            configuration that minimizes the average travel time.
##

from mosek.fusion import *
import sys


def main(args):
    n = 4
    arc_i = [0,    0,    2,    1,    2]
    arc_j = [1,    2,    1,    3,    3]
    arc_base = [4.0,  1.0,  2.0,  1.0,  6.0]
    arc_cap = [10.0, 12.0, 20.0, 15.0, 10.0]
    arc_sens = [0.1,  0.7,  0.9,  0.5,  0.1]

    T = 20.0
    source_idx = 0
    sink_idx = 3

    with Model() as M:
        narcs = len(arc_i)

        NxN = Set.make(n, n)
        sens = Matrix.sparse(n, n, arc_i, arc_j, arc_sens)
        cap = Matrix.sparse(n, n, arc_i, arc_j, arc_cap)
        basetime = Matrix.sparse(n, n, arc_i, arc_j, arc_base)
        e = Matrix.sparse(n, n, arc_i, arc_j, [1.0] * narcs)
        e_e = Matrix.sparse(n, n, [sink_idx], [source_idx], [1.0])

        cs_inv_matrix = \
            Matrix.sparse(n, n, arc_i, arc_j,
                          [1.0 / (arc_sens[i] * arc_cap[i]) for i in range(narcs)])
        s_inv_matrix = \
            Matrix.sparse(n, n, arc_i, arc_j,
                          [1.0 / arc_sens[i] for i in range(narcs)])

        x = M.variable("traffic_flow", NxN, Domain.greaterThan(0.0))

        t = M.variable("travel_time",  NxN, Domain.greaterThan(0.0))
        d = M.variable("d",            NxN, Domain.greaterThan(0.0))
        z = M.variable("z",            NxN, Domain.greaterThan(0.0))

        # Set the objective:
        M.objective("Average travel time",
                    ObjectiveSense.Minimize,
                    Expr.mul(1.0 / T, Expr.add(Expr.dot(basetime, x), Expr.dot(e, d))))

        # Set up constraints
        # Constraint (1a)
        numnz = len(arc_sens)

        v = Var.stack([[d.index(arc_i[i], arc_j[i]),
                        z.index(arc_i[i], arc_j[i]),
                        x.index(arc_i[i], arc_j[i])] for i in range(narcs)])

        M.constraint("(1a)", v, Domain.inRotatedQCone(narcs, 3))

        # Constraint (1b)
        c = M.constraint("(1b)",
                         Expr.sub(Expr.add(Expr.mulElm(z, e),
                                           Expr.mulElm(x, cs_inv_matrix)),
                                  s_inv_matrix),
                         Domain.equalsTo(0.0))
        # Constraint (2)
        M.constraint("(2)",
                     Expr.sub(Expr.add(Expr.mulDiag(x, e.transpose()),
                                       Expr.mulDiag(x, e_e.transpose())),
                              Expr.add(Expr.mulDiag(x.transpose(), e),
                                       Expr.mulDiag(x.transpose(), e_e))),
                     Domain.equalsTo(0.0))
        # Constraint (3)
        M.constraint("(3)", x.index(sink_idx, source_idx), Domain.equalsTo(T))

        M.solve()

        flow = x.level()

        print("Optimal flow:")
        for i, j in zip(arc_i, arc_j):
            print("\tflow node%d->node%d = %f" % (i, j, flow[i * n + j]))


main(sys.argv[1:])