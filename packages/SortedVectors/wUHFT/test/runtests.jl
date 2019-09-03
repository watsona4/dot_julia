using SortedVectors, Test

@testset "basics" begin
    sv = SortedVector([2,3,1])
    @test collect(sv) == [1, 2, 3]
    @test length(sv) == 3
    @test size(sv) == (3, )
    @test sv[1] == 1
    @test sv[2] == 2
    @test sv[3] == 3
    @test_throws BoundsError sv[4]
    @test_throws BoundsError sv[0]
    @test_throws BoundsError sv[-1]

    let T = typeof(sv)
        @test eltype(T) ≡ Int
        @test Base.IndexStyle(T) ≡ Base.IndexLinear()
    end

    let sim =  similar(sv)
        @test sim isa Vector{Int}
        @test length(sim) == length(sv)
    end

    @test_throws ArgumentError sv[1] = 7
    @test_throws ArgumentError sv[3] = -1
    @test (sv[1] = 0) == 0
    @test (sv[2] = 1) == 1
    @test (sv[3] = 8) == 8
    @test sv[:] == [0, 1, 8]

    @test parent(sv) ≡ sv.sorted_contents
    @test copy(sv) == sv

    @test_throws ArgumentError SortedVector(SortedVectors.CheckSorted(), isless, [3, 1, 2])
    @test SortedVector(SortedVectors.CheckSorted(), isless, [1, 2, 3]) == [1, 2, 3]
end

@testset "search and cut" begin
    sv = SortedVector(1:5)
    @test SortedVectors.cut.([1, 1.5, 2, 5, 6], Ref(sv)) == [0, 1, 1, 4, 5]
end
