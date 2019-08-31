# ConicBenchmarkUtilities

[![Build Status](https://travis-ci.org/JuliaOpt/ConicBenchmarkUtilities.jl.svg?branch=master)](https://travis-ci.org/JuliaOpt/ConicBenchmarkUtilities.jl)
[![codecov](https://codecov.io/gh/JuliaOpt/ConicBenchmarkUtilities.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaOpt/ConicBenchmarkUtilities.jl)

Utitilies to convert between [CBF](http://cblib.zib.de/) and [MathProgBase conic format](http://mathprogbasejl.readthedocs.io/en/latest/conic.html).

## How to read and solve a CBF instance:

```jl
dat = readcbfdata("/path/to/instance.cbf") # .cbf.gz extension also accepted

# In MathProgBase format:
c, A, b, con_cones, var_cones, vartypes, sense, objoffset = cbftompb(dat)
# Note: The sense in MathProgBase form is always minimization, and the objective offset is zero.
# If sense == :Max, you should flip the sign of c before handing off to a solver.

# Given the data in MathProgBase format, you can solve it using any corresponding solver which supports the cones present in the problem.
# To use ECOS, for example,
using ECOS
solver = ECOSSolver()
# Now load and solve
m = MathProgBase.ConicModel(ECOSSolver(verbose=0))
MathProgBase.loadproblem!(m, c, A, b, con_cones, var_cones)
# Continuous solvers need not implement setvartype!
if !all(vartypes .== :Cont)
    MathProgBase.setvartype!(m, vartypes)
end
MathProgBase.optimize!(m)
# Solution accessible through:
x_sol = MathProgBase.getsolution(m)
objval = MathProgBase.getobjval(m)
# If PSD vars are present, you can use the following utility to extract the solution in CBF form:
scalar_solution, psdvar_solution = ConicBenchmarkUtilities.mpb_sol_to_cbf(dat,x_sol)
```

## How to write a CBF instance:

```jl
newdat = mpbtocbf("example", c, A, b, con_cones, var_cones, vartypes, sense)
writecbfdata("example.cbf",newdat,"# Comment for the CBF header")
```

Note that because MathProgBase conic format is more general than CBF in specifying the mapping between variables and cones, *the order of the variables in the CBF file may not match the original order*. No reordering takes place if ``var_cones`` is trivial, i.e., ``[(:Free,1:N)]`` where ``N`` is the total number of variables.

## How to write a JuMP model to CBF form:

```jl
m = JuMP.Model()
@variable(m, x[1:2])
@variable(m, t)
@constraint(m, norm(x) <= t)
ConicBenchmarkUtilities.jump_to_cbf(m, "soctest", "soctest.cbf")
```
