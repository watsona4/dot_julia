using Test
using LinearAlgebra, ArnoldiMethod, ArnoldiMethodTransformations

@testset "generalized eigenvalue problem: " begin
    for i ∈ 1:1000
        # construct fixed eval matrix in random basis
        A = rand(ComplexF64,10,10)
        B = rand(ComplexF64,10,10)

        # find eigenpairs closest to .5
        decomp, hist = partialschur(A,B,.5)

        # get evecs
        λ, v = partialeigen(decomp,.5)

        @test norm(A*v-B*v*diagm(0=>λ)) ≤ sqrt(eps())
    end
end
