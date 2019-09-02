using ILog2
using Test

# FIXME: Tests for other floating point types

@testset "ILog2" begin
    bitstypes = (Int8, Int16, Int32, Int64,
                 UInt8, UInt16, UInt32, UInt64, Int128, UInt128)
    largest_Float64_corresponding_to_unique_integer = 2^53 - 1
    for T in  bitstypes
        N = min(typemax(T) - 1, largest_Float64_corresponding_to_unique_integer)
        num_trials_per_type = min(N, 10^4)
        nums = rand(T(1):T(N), num_trials_per_type)
        for n in nums
            @test ilog2(T(n)) == ilog2(float(n))
        end
    end
end

@testset "BigInt" begin
    for expt in rand(10:10^4, 10^3)
        n = big(2)^expt
        np = n + rand(1:100)
        nm = n - rand(1:100)
        @test ilog2(n) == expt
        @test ilog2(np) == expt
        @test ilog2(nm) == expt - 1
        @test ilog2(n) == ilog2(float(n))
    end
end

@testset "exceptions" begin
    @test_throws ArgumentError ILog2.msbindex(BigInt)
    @test_throws InexactError  ilog2(float(typemax(Int)-2^8))
    @test_throws DomainError ilog2(0)
    @test_throws DomainError ilog2(-1)
end
