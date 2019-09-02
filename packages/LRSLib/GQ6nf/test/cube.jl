@testset "Check consistency of LRSLib.HMatrix representation" begin
    A = [1 0; 0 1; -1 0; 0 -1]
    b = [1, 1, 0, 0]
    ine = hrep(A, b)
    inem1 = LRSLib.RepMatrix(ine)
    #setdebug(poly1, true)
    ine1  = MixedMatHRep{Int}(inem1)
    @test ine.A == ine1.A
    @test ine.b == ine1.b
    @test ine.linset == ine1.linset
end
