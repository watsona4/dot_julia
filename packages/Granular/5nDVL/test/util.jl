#!/usr/bin/env julia
import Granular
import Random
using Random
using Test

@info "Testing power-law RNG"

@test 1 == length(Granular.randpower())
@test () == size(Granular.randpower())
@test 1 == length(Granular.randpower(1))
@test () == size(Granular.randpower(1))
@test 4 == length(Granular.randpower((2,2)))
@test (2,2) == size(Granular.randpower((2,2)))
@test 5 == length(Granular.randpower(5))
@test (5,) == size(Granular.randpower(5))

Random.seed!(1)
for i=1:10^5
    @test 0. <= Granular.randpower() <= 1.
    @test 0. <= Granular.randpower(1, 1., 0., 1.) <= 1.
    @test 0. <= Granular.randpower(1, 1., 0., .1) <= .1
    @test 5. <= Granular.randpower(1, 1., 5., 6.) <= 6.
    @test 0. <= minimum(Granular.randpower((2,2), 1., 0., 1.))
    @test 1. >= maximum(Granular.randpower((2,2), 1., 0., 1.))
    @test 0. <= minimum(Granular.randpower(5, 1., 0., 1.))
    @test 1. >= minimum(Granular.randpower(5, 1., 0., 1.))
end

@test [1,2,0] == Granular.vecTo3d([1,2])
@test [1,2,3] == Granular.vecTo3d([1,2], fill=3)
@test [1,3,3] == Granular.vecTo3d([1], fill=3)
@test [1,3,3] == Granular.vecTo3d(1, fill=3)
@test [1.,2.,3.] == Granular.vecTo3d([1.,2.], fill=3.)
@test [1.,3.,3.] == Granular.vecTo3d(1., fill=3.)
@test [1.,0.,0.] == Granular.vecTo3d(1.)
@test [1.,0.,0.] == Granular.vecTo3d([1.])
