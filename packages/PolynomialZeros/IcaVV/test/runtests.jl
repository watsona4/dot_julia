using PolynomialZeros
using Polynomials
using Test
using LinearAlgebra

include("test-amvw.jl")
include("test-multroot.jl")


## Some Polynomial Familes
function Wilkinson(n, T=Float64)
    x = variable(T)
    prod(x-i for i in 1:n)
end

function Chebyshev(n, T=Float64)
    x = variable(T)
    n == 0 && return one(x)
    n == 1 && return x
    2 * x * Chebyshev(n-1, T) - Chebyshev(n-2, T)
end

function Legendre(n, T=Float64)
    x = variable(T)
    n == 0 && return one(x)
    n == 1 && return x
    1/(n+1) * ( (2n+1)*x*Legendre(n-1, T) - n * Legendre(n-2, T))
end

## only a few
function Cyclotomic(n, T=Float64)
    x = variable(T)
    n == 1 && return x-1
    n == 2 && return x + 1
    n == 5 && return x^4 + x^3 + x^2 + x + 1
    n == 10 && return x^4 - x^3 + x^2 -x + 1
    n == 20 && return x^8 - x^6 + x^4 - x^2 + 1
    throw(DomainError)
end



@testset "Over.C" begin
    @test length(poly_roots(Wilkinson(10), Over.C)) == 10
    @test length(poly_roots(x -> x^5 - x -1, Over.C)) == 5
    @test maximum(norm.(poly_roots(Chebyshev(5), Over.C))) <= 1

    p = Cyclotomic(20)
    rts = poly_roots(p, Over.C)
    @test maximum(norm.(p.(rts) ./ polyder(p).(rts))) <= 1e-14


    ## we have different methods
    rts = 1.0:6; p = poly(rts)
    fn = x -> x^5 - x - 1
    for m in [:PolynomialRoots, :roots, :amvw]
        @test maximum(norm.(sort(poly_roots(p, Over.C, method=m), by=norm) .- rts)) <= 1e-10
        poly_roots(fn, Over.C, method=m)
    end

    # test deflation
    fn = x -> x^3 * (x-1) * (x^2 + 1)
    @test sum(iszero.(poly_roots(fn, Over.C))) == 3

end

@testset "Over.R" begin
    @test length(poly_roots(Wilkinson(10), Over.R)) == 10
    @test length(poly_roots(x -> x^5 - x -1, Over.R)) == 1
    @test norm(poly_roots(x -> x^5 - x -1, Over.R)[1] - 1.1673039782614187) <= 1e-14
    @test maximum(norm.(poly_roots(Chebyshev(5), Over.R))) <= 1

    p = Legendre(11)
    rts = poly_roots(p, Over.R, square_free=true) # needs help here
    @test maximum(p.(rts) ./ polyder(p).(rts)) <= 1e-14


    p = poly([1.0, 2, 2, 3, 3, 3])
    rts = poly_roots(p, Over.R)
    @test length(rts) == 3

    # test deflation
    fn = x -> x^3 * (x-1) * (x^2 + 1)
    ds = sort(poly_roots(fn, Over.R)) .- sort([1,0])
    @test norm(ds) <= 1e-14


end

@testset "Over.Q" begin
    @test length(poly_roots(Wilkinson(5, Int), Over.Q)) == 5
    @test length(poly_roots(x -> x^5 - x -1, Over.Q)) == 0

    # test deflation
    fn = x -> x^3 * (x-1) * (x^2 + 1)
    ds = sort(poly_roots(fn, Over.R)) .- sort([1,0])
    @test norm(ds) <= 1e-14

    # test for input
    poly_roots(x -> x^4 - 1, Over.Q)
    poly_roots(x -> x^4 - 1//1, Over.Q)
    @test_throws ArgumentError poly_roots(x -> x^4 - 1.0, Over.Q)
end



@testset "Over.Z" begin
    @test length(poly_roots(x -> (x-1) * (2x-1) * (x^2 + 1), Over.Z)) == 1

    # test for input
    poly_roots(x -> x^4 - 1, Over.Z)
    @test_throws MethodError poly_roots(x -> x^4 - 1//1, Over.Z)
    @test_throws MethodError poly_roots(x -> x^4 - 1.0, Over.Z)
end


@testset "Over.Zp{q}" begin
    p = x -> x^8 - 1
    @test length(poly_roots(p, Over.Zp{7})) == 2
    @test length(poly_roots(p, Over.Zp{17})) == 8
end


@testset "special cases" begin
    x = variable()
    p = (x-1)*(x^2 + 1)
    rts_c = poly_roots(p, Over.C)
    rts_r = poly_roots(p, Over.R)
    @test length(rts_c) == 3
    @test length(rts_r) == 1

    x = variable(Int)
    p = (x-1)*(2x-3)
    rts_q = poly_roots(p, Over.Q)
    rts_z = poly_roots(p, Over.Z)
    @test length(rts_q) == 2
    @test length(rts_z) == 1
end


@testset "Different Types" begin

    FTs = [Float16, Float32, Float64, BigFloat]
    fn = x -> x^5 - x - 1
    fn1 = x -> (x-1)*(x-2)*(x^5 - x - 1)

    # over.C
    ## all methods promote, this just checks for errors
    for T in [Float64, BigFloat]
       poly_roots(fn, Over.CC{T}, method=:PolynomialRoots)
    end
    for T in [Float64]
       poly_roots(fn, Over.CC{T}, method=:roots)
    end
    for T in FTs
        poly_roots(fn, Over.CC{T}, method=:amvw)
    end
    @test_throws MethodError poly_roots(fn, Over.CC{Int})

    # over.R
    [@test eltype(poly_roots(fn, Over.RR{T})) == T for T in FTs]
    @test_throws MethodError poly_roots(fn, Over.RR{Int})

    # over.Z
    [poly_roots(fn1, Over.ZZ{T})  for T in [Int16, Int32, Int64, Int128]]
    @test eltype(poly_roots(fn1, Over.ZZ{Int32})) == Int32
    @test_throws MethodError poly_roots(fn1, Over.ZZ{Float64})

    p = poly([3.0])^5
    @test_throws MethodError poly_roots(p, Over.Z) # p has Float64 coefficients.
    @test poly_roots(convert(Poly{Int}, p), Over.Z) == [-3.0]

end
