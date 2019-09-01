using LinearAlgebra

@testset "Zhang-Yeung inequality" begin
    n = 4
    G = polymatroidcone(n, Polyhedra.DefaultLibrary{Float64}(lp_solver))
    # This vector is not entropic but it is a polymatroid
    invalidf = invalidfentropy(12)

    @testset "Basic tests" begin
        @test matusrentropy(1, 14) in G
        @test matusrentropy(1, 23) in G
        @test matusrentropy(1, 24) in G
        @test matusrentropy(2, 3) in G
        @test matusrentropy(2, 4) in G
        @testset "Non-entropic but polymatroid vector invalidf" begin
            @test invalidf in G
        end
    end

    # Let's cut it out !

    I = set(1)
    J = set(2)
    K = set(3)
    L = set(4)
    zhangyeungineq = 3(nonnegative(n,union(I,K)) + nonnegative(n,union(I,L)) + nonnegative(n,union(K,L))) +
                    nonnegative(n,union(J,K)) + nonnegative(n,union(J,L)) -
                    (nonnegative(n,I) + 2(nonnegative(n,K) + nonnegative(n,L)) + nonnegative(n,union(I,J)) +
                    4nonnegative(n,union(I,union(K,L))) + nonnegative(n,union(J,union(K,L))))
    @testset "Alternative expression" begin
        @test zhangyeunginequality() == zhangyeungineq
    end

    @testset "The Zhang-Yeung inequality is a new inequality..." begin
        @test !(zhangyeungineq in G)
    end
    @testset "...and it sees that invalidf is not a valid entropy" begin
        @test dot(zhangyeungineq, invalidf) == -1
    end
    # Actually, invalidf is even the certificate returned by CDD
    # to show that the Zhang-Yeung inequality is new
    #certificate = redundant(zhangyeungineq, G)[2]
    #certificate *= 2 / certificate[1]
    #@test PrimalEntropy{15,Int}(Array{Int}(certificate)) == invalidf
end
