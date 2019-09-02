using LowLevelFloatFunctions

if VERSION >= v"0.7.0-DEV"
    using Test
else
    using Base.Test
end


sqrt2₆₄ = sqrt(2.0); sqrt2₃₂ = sqrt(2.0f0); sqrt2₁₆ = sqrt(Float16(2.0));

@testset "constants" begin
    @test precision(Float16) == 11
    @test precision(Float32) == 24
    @test precision(Float64) == 53

    @test sign_bits(Float16) == 1
    @test sign_bits(Float32) == 1
    @test sign_bits(Float64) == 1

    @test significand_bits(Float16) == 10
    @test significand_bits(Float32) == 23
    @test significand_bits(Float64) == 52

    @test exponent_bits(Float16) == 5
    @test exponent_bits(Float32) == 8
    @test exponent_bits(Float64) == 11

    @test exponent_max(Float16) == 15
    @test exponent_max(Float32) == 127
    @test exponent_max(Float64) == 1023

    @test exponent_bias(Float16) == 15
    @test exponent_bias(Float32) == 127
    @test exponent_bias(Float64) == 1023

    @test exponent_field_max(Float16) == 16
    @test exponent_field_max(Float32) == 128
    @test exponent_field_max(Float64) == 1024

    @test exponent_min(Float16) == -14
    @test exponent_min(Float32) == -126
    @test exponent_min(Float64) == -1022
end

@testset "value_extraction" begin
    @test sign(-sqrt2₆₄) === -1.0
    @test sign(sqrt2₃₂) === 1.0f0
    @test sign(-sqrt2₁₆) === Float16(-1.0)
    @test exponent(-sqrt2₆₄) == 0
    @test exponent(sqrt2₃₂) == 0
    @test exponent(-sqrt2₁₆) == 0
    @test significand(-sqrt2₆₄) === -1.4142135623730951
    @test significand(sqrt2₃₂) === 1.4142135f0
    @test significand(-sqrt2₁₆) === Float16(-1.414)
end

@testset "field_get" begin
    @test sign_field(-sqrt2₆₄) === 0x0000000000000001
    @test sign_field(sqrt2₃₂) === 0x00000000
    @test sign_field(-sqrt2₁₆) === 0x0001
    @test exponent_field(-sqrt2₆₄) === 0x00000000000003ff
    @test exponent_field(sqrt2₃₂) === 0x0000007f
    @test exponent_field(-sqrt2₁₆) === 0x000f
    @test significand_field(sqrt2₆₄) === 0x0006a09e667f3bcd
    @test significand_field(sqrt2₃₂) === 0x003504f3
    @test significand_field(sqrt2₁₆) === 0x01a8
end

@testset "field_set" begin
    @test sign_field(-sqrt2₆₄, 0%UInt64) === 1.4142135623730951
    @test exponent_field(sqrt2₆₄, exponent_field(sqrt2₆₄)+one(UInt64)) === 2.8284271247461903
    @test significand_field(sqrt2₃₂, significand_field(sqrt2₃₂) - one(UInt32)) === prevfloat(sqrt2₃₂)
end

@testset "characterization" begin
    @test sign_bits(Float64) == 1
    @test exponent_bits(Float32) == 8
    @test significand_bits(Float16) == 10
    @test exponent_field_max(Float64) === 0x0000000000000400
    @test exponent_max(Float64) == 1023
    @test exponent_min(Float64) == -1022
    @test exponent_bias(Float32) == 127
end

@testset "utilitiarian" begin
    @test bitwidth(Float64) == 64
    @test bitwidth(Float32) == 32
    @test hexstring(sqrt2₆₄) == "3ff6a09e667f3bcd"
    @test hexstring(sqrt2₃₂) == "3fb504f3"
end
