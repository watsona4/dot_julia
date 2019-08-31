# ConicNonlinearBridge

[![Build Status](https://travis-ci.org/mlubin/ConicNonlinearBridge.jl.svg?branch=master)](https://travis-ci.org/mlubin/ConicNonlinearBridge.jl)
[![codecov](https://codecov.io/gh/mlubin/ConicNonlinearBridge.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/mlubin/ConicNonlinearBridge.jl)

This package implements a wrapper to allow derivative-based nonlinear solvers to function as [conic solvers](http://mathprogbasejl.readthedocs.org/en/latest/conic.html) for problems involving linear, (rotated) second-order, and exponential cones. For example:

    # min -2y -1z
    #  st  x == 1,
    #      x >= norm(y, z)
    using MathProgBase, ConicNonlinearBridge, Ipopt
    solver = ConicNLPWrapper(nlp_solver=IpoptSolver())
    m = MathProgBase.ConicModel(solver)
    MathProgBase.loadproblem!(m, [0, -2, -1], [1 0 0], [1], [(:Zero, 1)], [(:SOC, 1:3)])  
    MathProgBase.optimize!(m)
    MathProgBase.status(m) # :Optimal
    MathProgBase.getsolution(m) # [1.0, 0.894427, 0.447214]
    MathProgBase.getobjval(m) # -2.236067
    MathProgBase.freemodel!(m)

You may replace ``IpoptSolver`` above with any NLP solver (e.g. Knitro) accessible through MathProgBase, and you may pass valid options to the NLP solver directly (e.g. ``IpoptSolver(print_level=1)``.

This wrapper is experimental. If you are experiencing convergence troubles with existing conic solvers, this wrapper may be helpful. In general, however, specialized conic solvers are more reliable than derivative-based nonlinear solvers, especially for detection of infeasibility and unboundedness. If you find this wrapper useful, please let us know.
