# Example 1

using Base.Iterators
using Test
using Arbitrary

# Generate arbitrary values
xs = collect(take(arbitrary(BigInt), 100))
ys = collect(take(arbitrary(BigInt), 100))
zs = collect(take(arbitrary(BigInt), 100))

# Test commutativity
@test all(xs .+ ys .== ys .+ xs)
# Test associativity
@test all((xs .+ ys) .+ zs .== xs .+ (ys .+ zs))
