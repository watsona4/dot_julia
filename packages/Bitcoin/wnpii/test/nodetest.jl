@testset "Simple Node" begin
    @testset "Handshake" begin
        node = Node("btc.brane.cc", true)
        msg = Channel(2)
        @test Bitcoin.handshake(node, msg)
        Bitcoin.close!(node)
    end
    # @testset "GetHeaders" begin
    #     node = Node("btc.brane.cc", false)
    #     @test typeof(Bitcoin.getheaders(node, 1)) == Array{Bitcoin.BlockHeader,1}
    #     Bitcoin.close!(node)
    # end
    @testset "Using Bloom Filter" begin
        node = Node("btc.brane.cc", 18333, true, false)
        bf = BloomFilter(30, 5, 90210)
        adr = "mwJn1YPMq7y5F8J3LkC5Hxg9PHyZ5K4cFv"
        h160 = Base58.base58checkdecode(UInt8.(collect(adr)))[2:end]
        Bitcoin.add!(bf, h160)

        msg = Channel(2048)
        Bitcoin.handshake(node, msg)

        @async Bitcoin.read(node.sock)
        @async Bitcoin.read_messages(node, messages)

        last_block_hex = "00000000000538d5c2246336644f9a4956551afb44ba47278759ec55ea912e19"
        start_block = hex2bytes(last_block_hex)
        send2node(node, Bitcoin.FilterLoadMessage(bf))
        send2node(node, Bitcoin.GetHeadersMessage(start_block))

        println(Bitcoin.get_tx_of_interest(node, messages, adr))
    end
end
