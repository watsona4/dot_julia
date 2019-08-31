using OptionalData
using Test

struct TestType
    a::Float64
    b::Float64
    c::Float64
end

@OptionalData opt1 Symbol
@OptionalData opt2 TestType

@testset "OptionalData" begin
    @test string(opt1) == "OptData{Symbol}()"
    @test_throws ErrorException get(opt1)
    push!(opt1, :Test)
    @test string(opt1) == "OptData{Symbol}(Test)"
    @test get(opt1) == :Test
    push!(opt1, "Test")
    @test get(opt1) == :Test

    @test string(opt2) == "OptData{TestType}()"
    @test_throws ErrorException get(opt2)
    push!(opt2, TestType(1, 2, 3))
    @test string(opt2) == "OptData{TestType}(TestType(1.0, 2.0, 3.0))"
    @test get(opt2) == TestType(1, 2, 3)
    push!(opt2, 1, 2, 3)
    @test get(opt2) == TestType(1, 2, 3)
end
