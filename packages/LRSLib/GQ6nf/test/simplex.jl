@testset "Test representation conversion with the simplex" begin
    # A = [1 1; -1 0; 0 -1]
    # b = [1, 0, 0]
    # linset = BitSet([1])
    # V = [0 1; 1 0]

    A = [1 1; -1 0; 0 -1]
    b = [1, 0, 0]
    linset = BitSet()
    V = [0 0; 0 1; 1 0]

    function minitest(ine::LRSLib.HMatrix)
        ine  = MixedMatHRep{Int}(ine)
        @test sortslices([ine.b -ine.A], dims=1) == sortslices([b -A], dims=1)
        @test ine.linset == linset
    end
    function minitest(ext::LRSLib.VMatrix)
        ext  = MixedMatVRep{Int}(ext)
        @test sortslices(ext.V, dims=1) == V
        @test length(ext.R) == 0
        @test ext.Rlinset == BitSet()
    end

    ine = hrep(A, b, linset)
    ext = vrep(V)

    inem1 = LRSLib.HMatrix("simplex.ine")
    minitest(inem1)
    extm1 = convert(LRSLib.VMatrix, inem1)
    minitest(extm1)

    inem2 = LRSLib.RepMatrix(ine)
    minitest(inem2)
    extm2 = convert(LRSLib.VMatrix, inem2)
    minitest(extm2)

    extm3 = LRSLib.RepMatrix(ext)
    minitest(extm3)
    inem3 = convert(LRSLib.HMatrix, extm3)
    minitest(inem3)
end
