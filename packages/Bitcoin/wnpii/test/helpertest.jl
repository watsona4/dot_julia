@testset "Helper" begin
    @testset "VarString" begin
        @testset "Serialize" begin
            want = hex2bytes("0f2f5361746f7368693a302e372e322f")
            vstr = Bitcoin.VarString("/Satoshi:0.7.2/")
            @test Bitcoin.serialize(vstr) == want
        end
    end
end
