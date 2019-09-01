using Test
using ExpectationStubs: DoNotCare


@testset "DoNotCare is equal to everything" begin
    @test DoNotCare{Int}()==4
    @test 5==DoNotCare{Integer}()
    @test 5==DoNotCare{Any}()
    @test !(5===DoNotCare{Any}())

    @test 5!=DoNotCare{String}()

    @test (Any, DoNotCare{Any}()) === (Any,DoNotCare{Any}())
    @test !((Any, 1) === (Any,DoNotCare{Int}()))
end
