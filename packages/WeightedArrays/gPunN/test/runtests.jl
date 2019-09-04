
using WeightedArrays
using Test

R = Weighted(rand(3,10), rand(10))

@test size(R) == (3,10)
@test lastlength(R) == 10

@test sum(R.weights) ≈ 1 ## normalised in construction

R.weights .+= 1
normalise!(R)
@test sum(R.weights) ≈ 1 ## restored

S = sobol(2,9)

@test size(unique(S + S)) == size(S) ## hcat & unique

# @test size(unique!(clamp!(S .+ 2))) == (2,1) ## broadcast & clamp!
# @test size(unique!(clamp!(wrandn(2,9) .+ 2))) == (2,9)

X = xgrid(2,0:0.1:1)
X = near(X, S, 0.2)
@test size(X) == (2,78) ## near

# T = unique(symm(wgrid(1, 0:0.3:1)) )
# @test weights(T)[1] ≈ 0.25
