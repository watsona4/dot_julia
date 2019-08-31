using CatIndices
using Test

### BidirectionalVector
@testset "CatIndices" begin
    function checkvals(v)
        for i in axes(v,1)
            @test v[i] == i
        end
        nothing
    end
    @testset "BidirectionalVector" begin
        v = BidirectionalVector(1:3)
        @test axes(v,1) == 1:3
        checkvals(v)
        @test isa(push!(v, 4), BidirectionalVector)
        @test axes(v,1) == 1:4
        checkvals(v)
        @test isa(append!(v, 5:11), BidirectionalVector)
        @test axes(v,1) == 1:11
        checkvals(v)
        @test pop!(v) == 11
        @test axes(v,1) == 1:10
        checkvals(v)
        @test isa(deletetail!(v, 2), BidirectionalVector)
        @test axes(v,1) == 1:8
        checkvals(v)
        @test popfirst!(v) == 1
        @test axes(v,1) == 2:8
        checkvals(v)
        @test isa(pushfirst!(v, 0, 1), BidirectionalVector)
        @test isa(pushfirst!(v, -1), BidirectionalVector)
        @test axes(v,1) == -1:8
        checkvals(v)
        @test isa(prepend!(v, -5:-2), BidirectionalVector)
        @test axes(v,1) == -5:8
        checkvals(v)
        @test isa(deletehead!(v,2), BidirectionalVector)
        @test axes(v,1) == -3:8
        checkvals(v)

        v[0] = 200
        @test v[0] == 200

        @test axes(similar(v)) === axes(v)
        @test axes(similar(v, Float64)) === axes(v)
        @test axes(similar(v, Float64, 3)) === (Base.OneTo(3),)
        a = similar(Array{Float64}, axes(v))
        @test isa(a, BidirectionalVector)
        @test axes(a) === axes(v)
    end

    @testset "vcat" begin
        @test !CatIndices.is_pinned(1:3)
        @test CatIndices.is_pinned(PinIndices(1:3))
        v = vcat(1:3, PinIndices(4:5), 6:10)
        @test axes(v,1) == -2:7
        @test_throws ArgumentError vcat(1:3, PinIndices(4:5), PinIndices(6:10))
    end
end
