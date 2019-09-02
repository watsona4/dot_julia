##
#  Copyright : Copyright (c) MOSEK ApS, Denmark. All rights reserved.
#
#  File :      scopt1.py
#
#  Purpose :   Demonstrates how to solve a simple non-liner separable problem
#              using the SCopt interface for Python. The problem iss:
#
#              Minimize   e^x1 - ln(x0)
#              Such that  x1 ln(x1)   <= 0
#                         x0^1/2 - x1 >= 0
#                         1/2 <= x0, x1  <= 1
#
##

import sys
import mosek

def streamprinter(text):
    sys.stdout.write(text)
    sys.stdout.flush()


def main():
    with mosek.Env() as env:
        env.set_Stream(mosek.streamtype.log, streamprinter)
        with env.Task(0, 0) as task:
            task.set_Stream(mosek.streamtype.log, streamprinter)

            numvar = 2
            numcon = 2
            inf = 0.

            bkc = [mosek.boundkey.up,
                   mosek.boundkey.lo]
            blc = [-inf, 0.]
            buc = [0., inf]

            bkx = [mosek.boundkey.ra] * numvar
            blx = [0.5] * numvar
            bux = [1.0] * numvar

            task.appendvars(numvar)
            task.appendcons(numcon)

            task.putvarboundslice(0, numvar, bkx, blx, bux)
            task.putconboundslice(0, numcon, bkc, blc, buc)

            task.putaij(1, 1, -1.0)

            opro = [mosek.scopr.log, mosek.scopr.exp]
            oprjo = [0, 1]
            oprfo = [-1.0, 1.0]
            oprgo = [1.0, 1.0]
            oprho = [0.0, 0.0]

            oprc = [mosek.scopr.ent, mosek.scopr.pow]
            opric = [0, 1]
            oprjc = [1, 0]
            oprfc = [1.0, 1.0]
            oprgc = [0.0, 0.5]
            oprhc = [0.0, 0.0]

            task.putSCeval(opro, oprjo, oprfo, oprgo, oprho,
                           oprc, opric, oprjc, oprfc, oprgc, oprhc)

            task.optimize()

            res = [0.0] * numvar
            task.getsolutionslice(
                mosek.soltype.itr,
                mosek.solitem.xx,
                0, numvar,
                res)

            print("Solution is: %s" % res)
            task.putintparam(
                mosek.iparam.write_ignore_incompatible_items, mosek.onoffkey.on)
            task.writeSC("scprob.sc", "scprob.opf")

main()