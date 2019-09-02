
using Test
using NumberIntervals

const a = NumberInterval(-1, 0)
const b = NumberInterval(-0.5, 0.5)
const c = NumberInterval(0.5, 2)
const d = NumberInterval(0.25, 0.8)
const z = zero(NumberInterval)
const e = NumberInterval(Inf, -Inf)

@testset "number comparison" begin
    @test a < c
    @test c > a
    @test (a < b) |> ismissing
    @test (c > b) |> ismissing
    @test !(c < a)
    @test !(a > c)
    @test z == z
    @test z != c
    @test (a == b) |> ismissing
    @test (b != c) |> ismissing
    @test b <= c
end
@testset "testing for zero" begin
    @test !iszero(c)
    @test iszero(z)
    @test iszero(a) |> ismissing
    @test iszero(b) |> ismissing
end
@testset "test sign" begin
    @test signbit(c) == false
    @test signbit(-a) == false
    @test signbit(-c) == true
    @test signbit(a) |> ismissing
    @test sign(c) == 1
    @test sign(z) == 0
    @test sign(-c) == -1
    @test sign(b) |> ismissing
end
@testset "isinteger" begin
    @test isinteger(z)
    @test isinteger(NumberInterval(4))
    @test !isinteger(NumberInterval(4.5))
    @test isinteger(c) |> ismissing
    @test !isinteger(d)
end
@testset "isfinite" begin
    @test isfinite(a)
    @test isfinite(b)
    @test isfinite(c)
    @test isfinite(z)
    @test isfinite(NumberInterval(0., Inf))
    @test isfinite(e) |> ismissing
end
@testset "IndeterminateException" begin
    @test_throws IndeterminateException throw(IndeterminateException())
end
@testset "constructor" begin
    @test NumberInterval(a) === a
    @test NumberInterval{Float64}(a) === a
    @test NumberInterval{Float32}(4) isa NumberInterval{Float32}
    @test real(a) === a
    @test_throws ErrorException NumberInterval(2., 1.)
    @test isnan(NumberInterval(NaN))
    @test_throws ErrorException NumberInterval(Inf)
    @test_throws ErrorException NumberInterval(-Inf)
end
@testset "promotion" begin
    @test promote_rule(NumberInterval{Float32}, Float64) ==
        NumberInterval{Float64}
end
