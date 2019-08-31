using Test

include("zerorange.jl")
include("urange.jl")
include("zeroto.jl")  # deprecated

@test intersect(ZeroRange(4), URange(-1,2)) === 0:2
@test ZeroRange(6)[URange(2,4)] === 1:3

nothing
