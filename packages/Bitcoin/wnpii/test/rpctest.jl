@testset "REST Client" begin
    url = "http://btc.brane.cc:8332"
    @testset "GET Tx" begin
        key = "f4184fc596403b9d638783cf57adfe4c75c605f6356fbc91338530e9831e9e16"
        @test typeof(get_tx(key)) == Tx
    end
    @testset "GET Headers" begin
        key = "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f"
        headers = get_headers(key, amount=2)
        @test length(headers) == 2
        @test typeof(headers[1]) == BlockHeader
    end
    @testset "GET BlockHashByHeight" begin
        want = "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f"
        blockhash = get_blockhashbyheight(0)
        @test blockhash == want
    end
end
