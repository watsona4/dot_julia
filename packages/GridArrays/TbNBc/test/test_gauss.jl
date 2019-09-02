
using GridArrays , LinearAlgebra, Test

@testset "gauss" begin
    x1,w1 = GridArrays.gausschebyshev(10)
    x2,w2 = GridArrays.gausschebyshev(BigFloat,10)
    @test norm(x1-x2)+norm(w1-w2) < 1e-12

    x1,w1 = GridArrays.gausschebyshevu(10)
    x2,w2 = GridArrays.gausschebyshevu(BigFloat,10)
    @test norm(x1-x2)+norm(w1-w2) < 1e-12

    x1,w1 = GridArrays.gausslegendre(10)
    x2,w2 = GridArrays.gausslegendre(BigFloat,10)
    @test norm(x1-x2)+norm(w1-w2) < 1e-12

    a = rand()
    x1,w1 = GridArrays.gausslaguerre(10, a)
    x2,w2 = GridArrays.gausslaguerre(10, big(a))
    @test norm(x1-x2)+norm(w1-w2) < 1e-12

    x1,w1 = GridArrays.gausshermite(10)
    x2,w2 = GridArrays.gausshermite(10)
    @test norm(x1-x2)+norm(w1-w2) < 1e-12

    a= rand();b=rand()
    x1,w1 = GridArrays.gaussjacobi(10,a,b)
    x2,w2 = GridArrays.gaussjacobi(10,big(a),big(b))
    @test norm(x1-x2)+norm(w1-w2) < 1e-12

    a= -.5
    x1,w1 = GridArrays.gaussjacobi(10,a,a)
    x2,w2 = GridArrays.gaussjacobi(10,big(a),big(a))
    x,w = GridArrays.gausschebyshev(10)
    @test w≈w1
    @test x≈x1
    x,w = GridArrays.gausschebyshev(BigFloat,10)
    @test x≈x2
    @test w≈w2

    a= .5
    x1,w1 = GridArrays.gaussjacobi(10,a,a)
    x2,w2 = GridArrays.gaussjacobi(10,big(a),big(a))
    x,w = GridArrays.gausschebyshevu(10)
    @test w≈w1
    @test x≈x1
    x,w = GridArrays.gausschebyshevu(BigFloat,10)
    @test x≈x2
    @test w≈w2
end
