using Test, MirroredArrayViews, Random

const A1 = [1 2
            3 4]

const A2 = [1, 2, 3, 4, 5]

@testset "mirror_vector" begin
    @test MirroredArrayView(A2, 1) == [5, 4, 3, 2, 1]
    @test_throws BoundsError MirroredArrayView(A2, 2)
    @test MirroredArrayView(MirroredArrayView(A2, 1), 1) == A2
end

@testset "mirror_matrix" begin
    @test MirroredArrayView(A1, 1) == [3 4
                                       1 2]

    @test MirroredArrayView(A1, 2) == [2 1
                                       4 3]

    @test MirroredArrayView(A1, 1, 2) == [4 3
                                          2 1]
    @test MirroredArrayView(A1, 2, 1) == MirroredArrayView(A1, 1, 2)

    @test_throws BoundsError MirroredArrayView(A1, 3)
    @test_throws BoundsError MirroredArrayView(A1, 1, 2, 3)

    @test begin
        B = MirroredArrayView(A1, 1)
        C = similar(B)
        C .= B
        MirroredArrayView(C, 1) == A1
    end

    @test begin
        B = MirroredArrayView(A1, 2)
        C = similar(B)
        C .= B
        MirroredArrayView(C, 2) == A1
    end

    @test begin
        B = MirroredArrayView(A1, 1, 2)
        C = similar(B)
        C .= B
        MirroredArrayView(C, 2, 1) == A1
    end
end

@testset "general array mirrors" begin
    # Test that mirroring an array of arbitrary dimension (<= 10 for
    # these tests to keep it reasonable) in some number of dimensions and
    # then mirroring back in each dimension preserves the parent array.

    # Number of base arrays.
    outer_iters = 10

    # Number of combinations of dimensions to test for each array
    inner_iters = 5
    
    # Limit to array sizes
    maxdims = 10
    maxsize = 5

    for iter = 1:outer_iters
        dim = rand(3:maxdims)
        A = rand(Int, ( (rand(1:maxsize) for i = 1:dim)..., ))
        println("A has size $(size(A))")

        for iiter = 1:inner_iters
            dims = ( shuffle!([i for i = 1:rand(1:dim)])..., )
            println("    Mirroring A along $(dims)")
            B = MirroredArrayView(A, dims...)
            
            for i = length(dims):-1:1
                unmirror = dims[i:length(dims)]
                mirror = dims[1:i-1]
                println("      Testing mirror(A, $mirror) == mirror(mirror(A, $dims), $unmirror)")
                @test MirroredArrayView(A, mirror...) ==
                      MirroredArrayView(B, unmirror...)
            end
        end
    end
end

