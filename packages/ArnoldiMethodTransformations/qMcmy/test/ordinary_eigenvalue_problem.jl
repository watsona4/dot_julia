using Test
using LinearAlgebra, ArnoldiMethod, ArnoldiMethodTransformations

# construct fixed eval matrix in random basis
D = diagm(0=>[0,1,2,3,4,5,6,7,8,9])

@testset "ordinary eigenvalue problem: " begin
    for i ∈ 1:1000
        S = I + .1*randn(10,10) # random basis
        A = S\D*S

        # find eigenpairs closest to 5.001 (cannot be 5 as algorithm is unstable if σ is exactly an eval)
        decomp, hist = partialschur(A,5.001)

        # get evecs
        λ, v = partialeigen(decomp,5.001)

        @test norm(A*v-v*diagm(0=>λ)) ≤ sqrt(eps())
    end
end
