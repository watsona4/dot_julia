# floating point tests used in Julia Base

@testset "flipsign" begin
    x = convert(Single32,-2.0)
    x = flipsign(x,-1.0)
    @test flipsign(x,big(-1.0)) == convert(Single32,-2.0)
end

@testset "maxintfloat" begin
    @test maxintfloat(Single32, Int64) === maxintfloat(Float32, Int64)
    @test maxintfloat(Single32, Int32) === maxintfloat(Float32, Int32)
    @test maxintfloat(Single32, Int16) === maxintfloat(Float32, Int16)
end

@testset "isinteger" begin
    @test !isinteger(Single32(1.2))
    @test isinteger(Single32(12))
    @test isinteger(zero(Single32))
    @test isinteger(-zero(Single32))
    @test !isinteger(nextfloat(zero(Single32)))
    @test !isinteger(prevfloat(zero(Single32)))
    @test isinteger(maxintfloat(Single32))
    @test isinteger(-maxintfloat(Single32))
    @test !isinteger(Single32(Inf))
    @test !isinteger(-Single32(Inf))
    @test !isinteger(Single32(NaN))
end

@testset "round" begin
    x = Single32(rand(Float32))
    A = fill(x,(10,10))
    @test round.(A,RoundToZero) == fill(trunc(x),(10,10))
    @test round.(A,RoundUp) == fill(ceil(x),(10,10))
    @test round.(A,RoundDown) == fill(floor(x),(10,10))
    A = fill(x,(10,10,10))
    @test round.(A,RoundToZero) == fill(trunc(x),(10,10,10))
    @test round.(A,RoundUp) == fill(ceil(x),(10,10,10))
    @test round.(A,RoundDown) == fill(floor(x),(10,10,10))
end

@testset "round2" begin
    x = Single32(rand(Float32))
    for elty2 in (Int32,Int64)
        A = fill(x,(10,))
        @test round.(elty2,A,RoundToZero) == fill(trunc(elty2,x),(10,))
        @test round.(elty2,A,RoundUp) == fill(ceil(elty2,x),(10,))
        @test round.(elty2,A,RoundDown) == fill(floor(elty2,x),(10,))
        A = fill(x,(10,10))
        @test round.(elty2,A,RoundToZero) == fill(trunc(elty2,x),(10,10))
        @test round.(elty2,A,RoundUp) == fill(ceil(elty2,x),(10,10))
        @test round.(elty2,A,RoundDown) == fill(floor(elty2,x),(10,10))
        A = fill(x,(10,10,10))
        @test round.(elty2,A,RoundToZero) == fill(trunc(elty2,x),(10,10,10))
        @test round.(elty2,A,RoundUp) == fill(ceil(elty2,x),(10,10,10))
        @test round.(elty2,A,RoundDown) == fill(floor(elty2,x),(10,10,10))
        @test round.(elty2,A) == fill(round(elty2,x),(10,10,10))
    end
end
