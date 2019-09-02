# Validated from http://www.ams.jhu.edu/~castello/625.414/Handouts/FractionalProg.pdf
using LinearFractional
using Clp
using JuMP

lfp = LinearFractionalModel(solver=ClpSolver())
x = @variable(lfp, [i=1:2], basename="x", lowerbound=0)
@constraint(lfp, x[2] <= 6)
@constraint(lfp, -x[1] + x[2] <= 4)
@constraint(lfp, 2x[1] + x[2] <= 14)
a = [-2, 1]
@numerator(lfp,  :Min, sum(a[i] * x[i] for i in 1:2) + 2)
@denominator(lfp,  x[1] + 3x[2] + 4)
solve(lfp)
getobjectivevalue(lfp)
getvalue(x)
