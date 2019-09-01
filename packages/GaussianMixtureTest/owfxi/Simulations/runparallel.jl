# run the simulation

import GaussianMixtureTest
using Distributed
using DelimitedFiles

include(joinpath(dirname(pathof(GaussianMixtureTest)), "..",  "test/CompareAcuracy.jl"))
@everywhere Ctrue = 3
@everywhere C_max = max(5, (2*Ctrue - 1))
@everywhere B=200
@everywhere n_vec = [80, 100, 200, 300, 500, 800, 1000]
@everywhere nn = length(n_vec)

for ik in 1:nn
    @everywhere n = $(n_vec[ik])
    teststat = pmap((b) -> compareBIC(Ctrue, n, b), 1:B)
    writedlm("compare_$(Ctrue)_$(n).csv", teststat)
end
