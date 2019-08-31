using Base58, BitConverter
@testset "Script" begin
    @testset "parse" begin
        script_pubkey = IOBuffer(hex2bytes("6a47304402207899531a52d59a6de200179928ca900254a36b8dff8bb75f5f5d71b1cdc26125022008b422690b8461cb52c3cc30330b23d574351872b7c361e9aae3649071c1a7160121035d5c93d9ac96881f19ba1f686f15f009ded7c62efe85a872e6a19b43c15a2937"))
        script = Bitcoin.scriptparse(script_pubkey)
        want = hex2bytes("304402207899531a52d59a6de200179928ca900254a36b8dff8bb75f5f5d71b1cdc26125022008b422690b8461cb52c3cc30330b23d574351872b7c361e9aae3649071c1a71601")
        @test script.instructions[1] == want
        want = hex2bytes("035d5c93d9ac96881f19ba1f686f15f009ded7c62efe85a872e6a19b43c15a2937")
        @test script.instructions[2] == want
        script_pubkey = IOBuffer(hex2bytes("fdfe0000483045022100c679944ff8f20373685e1122b581f64752c1d22c67f6f3ae26333aa9c3f43d730220793233401f87f640f9c39207349ffef42d0e27046755263c0a69c436ab07febc01483045022100eadc1c6e72f241c3e076a7109b8053db53987f3fcc99e3f88fc4e52dbfd5f3a202201f02cbff194c41e6f8da762e024a7ab85c1b1616b74720f13283043e9e99dab8014c69522102b0c7be446b92624112f3c7d4ffc214921c74c1cb891bf945c49fbe5981ee026b21039021c9391e328e0cb3b61ba05dcc5e122ab234e55d1502e59b10d8f588aea4632102f3bd8f64363066f35968bd82ed9c6e8afecbd6136311bb51e91204f614144e9b53aeffffffff05a08601000000000017a914081fbb6ec9d83104367eb1a6a59e2a92417d79298700350c00000000001976a914677345c7376dfda2c52ad9b6a153b643b6409a3788acc7f341160000000017a914234c15756b9599314c9299340eaabab7f1810d8287c02709000000000017a91469be3ca6195efcab5194e1530164ec47637d44308740420f00000000001976a91487fadba66b9e48c0c8082f33107fdb01970eb80388ac00000000"))
        want = hex2bytes("522102b0c7be446b92624112f3c7d4ffc214921c74c1cb891bf945c49fbe5981ee026b21039021c9391e328e0cb3b61ba05dcc5e122ab234e55d1502e59b10d8f588aea4632102f3bd8f64363066f35968bd82ed9c6e8afecbd6136311bb51e91204f614144e9b53ae")
        script = Bitcoin.scriptparse(script_pubkey)
        @test script.instructions[4] == want
    end
    @testset "Serialize" begin
        want = "6a47304402207899531a52d59a6de200179928ca900254a36b8dff8bb75f5f5d71b1cdc26125022008b422690b8461cb52c3cc30330b23d574351872b7c361e9aae3649071c1a7160121035d5c93d9ac96881f19ba1f686f15f009ded7c62efe85a872e6a19b43c15a2937"
        script_pubkey = IOBuffer(hex2bytes(want))
        script = Bitcoin.scriptparse(script_pubkey)
        @test bytes2hex(Bitcoin.serialize(script)) == want
    end
    @testset "Evaluate" begin
        modified_tx = hex2bytes("0100000001813f79011acb80925dfe69b3def355fe914bd1d96a3f5f71bf8303c6a989c7d1000000001976a914a802fc56c704ce87c42d7c92eb75e7896bdc41ae88acfeffffff02a135ef01000000001976a914bc3b654dca7e56b04dca18f2566cdaf02e8d9ada88ac99c39800000000001976a9141c4bc762dd5423e332166702cb75f40df79fea1288ac1943060001000000")
        h256 = Bitcoin.hash256(modified_tx)
        z = to_int(h256)
        stream = IOBuffer(hex2bytes("0100000001813f79011acb80925dfe69b3def355fe914bd1d96a3f5f71bf8303c6a989c7d1000000006b483045022100ed81ff192e75a3fd2304004dcadb746fa5e24c5031ccfcf21320b0277457c98f02207a986d955c6e0cb35d446a89d3f56100f4d7f67801c31967743a9c8e10615bed01210349fc4e631e3624a545de3f89f5d8684c7b8138bd94bdd531d2e213bf016b278afeffffff02a135ef01000000001976a914bc3b654dca7e56b04dca18f2566cdaf02e8d9ada88ac99c39800000000001976a9141c4bc762dd5423e332166702cb75f40df79fea1288ac19430600"))
        tx = parse(stream)::Tx
        tx_in = tx.tx_ins[1]
        combined_script = Bitcoin.Script(nothing)
        append!(combined_script.instructions, copy(tx_in.script_sig.instructions))
        append!(combined_script.instructions, copy(Bitcoin.script_pubkey(tx_in).instructions))
        @test Bitcoin.evaluate(combined_script, z) == true
    end
    @testset "Address" begin
        address_1 = "1BenRpVUFK65JFWcQSuHnJKzc4M8ZP8Eqa"
        h160 = base58checkdecode(UInt8.(collect(address_1)))[2:end]
        p2pkh_script_pubkey = Bitcoin.p2pkh_script(h160)
        @test script2address(p2pkh_script_pubkey, false) == address_1
        address_2 = "mrAjisaT4LXL5MzE81sfcDYKU3wqWSvf9q"
        @test script2address(p2pkh_script_pubkey, true) == address_2
        address_3 = "3CLoMMyuoDQTPRD3XYZtCvgvkadrAdvdXh"
        h160 = base58checkdecode(UInt8.(collect(address_3)))[2:end]
        p2sh_script_pubkey = Bitcoin.p2sh_script(h160)
        @test script2address(p2sh_script_pubkey, false) == address_3
        address_4 = "2N3u1R6uwQfuobCqbCgBkpsgBxvr1tZpe7B"
        @test script2address(p2sh_script_pubkey, true) == address_4
    end
    @testset "P2WPKH" begin
        h160 = hex2bytes("74d691da1574e6b3c192ecfb52cc8984ee7b6c56")
        p2wpkh_script = Bitcoin.p2wpkh_script(h160)
        @test Bitcoin.is_p2wpkh(p2wpkh_script)
    end
end
