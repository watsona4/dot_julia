##
#  Copyright: Copyright (c) MOSEK ApS, Denmark. All rights reserved.
#
#  File:      lownerjohn_ellipsoid.py
#
#  Purpose:
#  Computes the Lowner-John inner and outer ellipsoidal
#  approximations of a polytope.
#
#  Note:
#  To plot the solution the Python package matplotlib is required.
#
#  References:
#    [1] "Lectures on Modern Optimization", Ben-Tal and Nemirovski, 2000.
#    [2] "MOSEK modeling manual", 2013
##

import sys
from math import sqrt, ceil, log
from mosek.fusion import *

'''
Models the convex set 

  S = { (x, t) \in R^n x R | x >= 0, t <= (x1 * x2 * ... * xn)^(1/n) }

as  the intersection of rotated quadratic cones and affine hyperplanes.
see [1, p. 105] or [2, p. 21].  This set can be interpreted as the hypograph of the 
geometric mean of x.

We illustrate the modeling procedure using the following example.
Suppose we have 

   t <= (x1 * x2 * x3)^(1/3)

for some t >= 0, x >= 0. We rewrite it as

   t^4 <= x1 * x2 * x3 * x4,   x4 = t

which is equivalent to (see [1])

   x11^2 <= 2*x1*x2,   x12^2 <= 2*x3*x4,

   x21^2 <= 2*x11*x12,

   sqrt(8)*x21 = t, x4 = t.
'''
def geometric_mean(M, x, t):
    def rec(x):
        n = x.getShape().dim(0)
        if n > 1:
            y = M.variable(int(n // 2), Domain.unbounded())
            M.constraint(Var.hstack(Var.reshape(
                x, [n // 2, 2]), y), Domain.inRotatedQCone())
            return rec(y)
        else:
            return x

    n = x.getShape().dim(0)
    l = int(ceil(log(n, 2)))
    m = int(2**l) - n

    # if size of x is not a power of 2 we pad it:
    if m > 0:
        x_padding = M.variable(m, Domain.unbounded())

        # set the last m elements equal to t
        M.constraint(Expr.sub(x_padding, Var.repeat(t, m)),
                     Domain.equalsTo(0.0))

        x = Var.vstack(x, x_padding)

    M.constraint(Expr.sub(Expr.mul(2.0**(l / 2.0), t), rec(x)),
                 Domain.equalsTo(0.0))


'''
 Purpose: Models the hypograph of the n-th power of the
 determinant of a positive definite matrix. See [1,2] for more details.

   The convex set (a hypograph)

   C = { (X, t) \in S^n_+ x R |  t <= det(X)^{1/n} },

   can be modeled as the intersection of a semidefinite cone

   [ X, Z; Z^T Diag(Z) ] >= 0  

   and a number of rotated quadratic cones and affine hyperplanes,

   t <= (Z11*Z22*...*Znn)^{1/n}  (see geometric_mean).
'''
def det_rootn(M, X, t):
    n = int(sqrt(X.size()))

    # Setup variables
    Y = M.variable(Domain.inPSDCone(2 * n))

    # Setup Y = [X, Z; Z^T , diag(Z)]
    Y11 = Y.slice([0, 0], [n, n])
    Y21 = Y.slice([n, 0], [2 * n, n])
    Y22 = Y.slice([n, n], [2 * n, 2 * n])

    M.constraint(Expr.sub(Y21.diag(), Y22.diag()), Domain.equalsTo(0.0))
    M.constraint(Expr.sub(X, Y11), Domain.equalsTo(0.0))

    # t^n <= (Z11*Z22*...*Znn)
    geometric_mean(M, Y22.diag(), t)

'''
  The inner ellipsoidal approximation to a polytope 

     S = { x \in R^n | Ax < b }.

  maximizes the volume of the inscribed ellipsoid,

     { x | x = C*u + d, || u ||_2 <= 1 }.

  The volume is proportional to det(C)^(1/n), so the
  problem can be solved as 

    maximize         t
    subject to       t       <= det(C)^(1/n)
                || C*ai ||_2 <= bi - ai^T * d,  i=1,...,m
                C is PSD

  which is equivalent to a mixed conic quadratic and semidefinite
  programming problem.
'''
def lownerjohn_inner(A, b):
    with Model("lownerjohn_inner") as M:
        M.setLogHandler(sys.stdout)
        m, n = len(A), len(A[0])

        # Setup variables
        t = M.variable("t", 1, Domain.greaterThan(0.0))
        C = M.variable("C", Domain.inPSDCone(n))
        d = M.variable("d", n, Domain.unbounded())

        # (b-Ad, AC) generate cones
        M.constraint("qc", Expr.hstack(Expr.sub(b, Expr.mul(A, d)), Expr.mul(A, C)),
                     Domain.inQCone())
        # t <= det(C)^{1/n}
        det_rootn(M, C, t)

        # Objective: Maximize t
        M.objective(ObjectiveSense.Maximize, t)

        M.solve()

        C, d = C.level(), d.level()
        return ([C[i:i + n] for i in range(0, n * n, n)], d)

'''
  The outer ellipsoidal approximation to a polytope given 
  as the convex hull of a set of points

    S = conv{ x1, x2, ... , xm }

  minimizes the volume of the enclosing ellipsoid,

    { x | || P*x-c ||_2 <= 1 }

  The volume is proportional to det(P)^{-1/n}, so the problem can
  be solved as

    maximize         t
    subject to       t       <= det(P)^(1/n)
                || P*xi - c ||_2 <= 1,  i=1,...,m
                P is PSD.
'''
def lownerjohn_outer(x):
    with Model("lownerjohn_outer") as M:
        M.setLogHandler(sys.stdout)
        m, n = len(x), len(x[0])

        # Setup variables
        t = M.variable("t", 1, Domain.greaterThan(0.0))
        P = M.variable("P", Domain.inPSDCone(n))
        c = M.variable("c", n, Domain.unbounded())

        # (1, Px-c) in cone
        M.constraint("qc",
                     Expr.hstack(Expr.ones(m),
                                 Expr.sub(Expr.mul(x, P),
                                          Var.reshape(Var.repeat(c, m), [m, n])
                                          )
                                 ),
                     Domain.inQCone())

        # t <= det(P)^{1/n}
        det_rootn(M, P, t)

        # Objective: Maximize t
        M.objective(ObjectiveSense.Maximize, t)
        M.solve()

        P, c = P.level(), c.level()
        return ([P[i:i + n] for i in range(0, n * n, n)], c)

##########################################################################

if __name__ == '__main__':
    #Vertices of a pentagon in 2D
    p = [[0., 0.], [1., 3.], [5.5, 4.5], [7., 4.], [7., 1.], [3., -2.]]
    nVerts = len(p)

    #The hyperplane representation of the same polytope
    A = [[-p[i][1] + p[i - 1][1], p[i][0] - p[i - 1][0]]
         for i in range(len(p))]
    b = [A[i][0] * p[i][0] + A[i][1] * p[i][1] for i in range(len(p))]

    Po, co = lownerjohn_outer(p)
    Ci, di = lownerjohn_inner(A, b)

    #Visualization
    try:
        import numpy as np
        import matplotlib
        matplotlib.use('Agg')
        import matplotlib.pyplot as plt
        import matplotlib.patches as patches

        #Polygon
        fig = plt.figure()
        ax = fig.add_subplot(111)
        ax.add_patch(patches.Polygon(p, fill=False, color="red"))
        #The inner ellipse
        theta = np.linspace(0, 2 * np.pi, 100)
        x = Ci[0][0] * np.cos(theta) + Ci[0][1] * np.sin(theta) + di[0]
        y = Ci[1][0] * np.cos(theta) + Ci[1][1] * np.sin(theta) + di[1]
        ax.plot(x, y)
        #The outer ellipse
        x, y = np.meshgrid(np.arange(-1.0, 8.0, 0.025),
                           np.arange(-3.0, 6.5, 0.025))
        ax.contour(x, y,
                   (Po[0][0] * x + Po[0][1] * y - co[0])**2 + (Po[1][0] * x + Po[1][1] * y - co[1])**2, [1])
        ax.autoscale_view()
        ax.xaxis.set_visible(False)
        ax.yaxis.set_visible(False)
        fig.savefig('ellipsoid.png')
    except:
        print("Inner:")
        print("  C = ", Ci)
        print("  d = ", di)
        print("Outer:")
        print("  P = ", Po)
        print("  c = ", co)