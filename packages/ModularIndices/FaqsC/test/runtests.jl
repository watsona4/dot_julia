using ModularIndices
using Test, OffsetArrays, StaticArrays

@testset "0-d" begin
    for A in (fill(1), (x=Array{Int,0}(undef);x[]=1;x))
        @test A[Mod(5)] == 1
        @test A[Mod(-1)] == 1
        @test A[Mod(2:3)] == [1, 1]
        @test A[Mod(2, 30)] == [1, 1]
        @test A[Mod([5])] == [1]
        @test A[Mod(SVector(5))] == [1]
        A[Mod(2)] = 2
        @test A[] == 2
    end
end


@testset "1-d" begin
    for A in (1:10, collect(1:10), rand(10), @SVector(rand(10)), @MVector(rand(10)))
        @test A[Mod(11)] == A[1]
        @test A[Mod(12)] == A[2]
        @test A[Mod(1)] == A[1]
        @test A[Mod(1,2)] == A[[1,2]]
        @test A[Mod(11:15)] == A[1:5]
        @test A[Mod(SVector(11,12))] == A[[1,2]]
    end

    A = collect(1:5)
    A[Mod(7)] = 0
    @test A == [1,0,3,4,5]
end

@testset "2-d" begin
    for A in (rand(5,5), @SMatrix(rand(5,5)), view(rand(10,10), 1:5, 1:5))
        @test A[Mod(11), 2] == A[1, 2]
        @test A[2, Mod(11)] == A[2, 1]

        @test A[Mod(11:12), 2] == A[1:2, 2]
        @test A[Mod(11,12), 1] == A[1:2, 1]
    end

    A = OffsetArray(reshape(-10:13,3,:), -1, 0)
    # axes(A) == (Base.IdentityUnitRange(0:2), Base.IdentityUnitRange(1:8))
    @test A[Mod(3), 1] == A[0, 1]
    @test A[0, Mod(9)] == A[0, 1]
end


@testset "Invalid constructions" begin
    @test_throws MethodError Mod(1.5)
    @test_throws MethodError Mod([1.5, 2.5])
    @test_throws MethodError Mod(1.5, 2.5)
    @test_throws MethodError Mod(1:.1:2)
    @test_throws MethodError Mod((1,2,3))
end
