# Copyright (c) 2019 Simon Castano
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

@testset "Transaction" begin
    @testset "TxIn" begin
        txin_hex = "7b1eabe0209b1fe794124575ef807057c77ada2138ae4fa8d6c4de0398a14f3f00000000494830450221008949f0cb400094ad2b5eb399d59d01c14d73d8fe6e96df1a7150deb388ab8935022079656090d7f6bac4c9a94e0aad311a4268e082a725f8aeae0573fb12ff866a5f01ffffffff"
        raw = hex2bytes(txin_hex)
        txin = TxIn(IOBuffer(raw))
        @test typeof(txin.prevout) == Outpoint
        @test bytes2hex(txin.prevout.txid) == "3f4fa19803dec4d6a84fae3821da7ac7577080ef75451294e71f9b20e0ab1e7b"
        @test txin.prevout.index == 0
        want = hex2bytes("30450221008949f0cb400094ad2b5eb399d59d01c14d73d8fe6e96df1a7150deb388ab8935022079656090d7f6bac4c9a94e0aad311a4268e082a725f8aeae0573fb12ff866a5f01")
        @test txin.scriptsig.data == [want]
        @test txin.sequence == 0xffffffff
    end
    @testset "TxOut" begin
        txout_hex = "f0ca052a010000001976a914cbc20a7664f2f69e5355aa427045bc15e7c6c77288ac"
        raw = hex2bytes(txout_hex)
        txout = TxOut(IOBuffer(raw))
        @test txout.value == 4999990000
        @test txout.scriptpubkey.data == [[0x76], [0xa9], hex2bytes("cbc20a7664f2f69e5355aa427045bc15e7c6c772"), [0x88], [0xac]]
    end

    raw_tx = hex2bytes("0100000001813f79011acb80925dfe69b3def355fe914bd1d96a3f5f71bf8303c6a989c7d1000000006b483045022100ed81ff192e75a3fd2304004dcadb746fa5e24c5031ccfcf21320b0277457c98f02207a986d955c6e0cb35d446a89d3f56100f4d7f67801c31967743a9c8e10615bed01210349fc4e631e3624a545de3f89f5d8684c7b8138bd94bdd531d2e213bf016b278afeffffff02a135ef01000000001976a914bc3b654dca7e56b04dca18f2566cdaf02e8d9ada88ac99c39800000000001976a9141c4bc762dd5423e332166702cb75f40df79fea1288ac19430600")
    raw_bip141 = hex2bytes("0100000000010115e180dc28a2327e687facc33f10f2a20da717e5548406f7ae8b4c811072f85601000000000fffffff0100b4f505000000001976a9141d7cd6c75c2e86f4cbf98eaed221b30bd9a0b92888ac02483045022100df7b7e5cda14ddf91290e02ea10786e03eb11ee36ec02dd862fe9a326bbcb7fd02203f5b4496b667e6e281cc654a2da9e4f08660c620a1051337fa8965f727eb19190121038262a6c6cec93c2d3ecd6c6072efea86d02ff8e3328bbd0242b20af3425990ac00000000")
    @testset "Parsing" begin
        @testset "Legacy" begin
            tx = Tx(IOBuffer(raw_tx))
            @test tx.version == 1
            @test tx.locktime == 0x00064319
            @testset "Inputs" begin
                @test length(tx.inputs) == 1
                want = hex2bytes("d1c789a9c60383bf715f3f6ad9d14b91fe55f3deb369fe5d9280cb1a01793f81")
                @test tx.inputs[1].prevout.txid == want
                @test tx.inputs[1].prevout.index == 0
                want = hex2bytes("6b483045022100ed81ff192e75a3fd2304004dcadb746fa5e24c5031ccfcf21320b0277457c98f02207a986d955c6e0cb35d446a89d3f56100f4d7f67801c31967743a9c8e10615bed01210349fc4e631e3624a545de3f89f5d8684c7b8138bd94bdd531d2e213bf016b278a")
                @test serialize(tx.inputs[1].scriptsig) == want
                @test tx.inputs[1].sequence == 0xfffffffe
            end
            @testset "Outputs" begin
                @test length(tx.outputs) == 2
                want = 32454049
                @test tx.outputs[1].value == want
                want = hex2bytes("1976a914bc3b654dca7e56b04dca18f2566cdaf02e8d9ada88ac")
                @test serialize(tx.outputs[1].scriptpubkey) == want
                want = 10011545
                @test tx.outputs[2].value == want
                want = hex2bytes("1976a9141c4bc762dd5423e332166702cb75f40df79fea1288ac")
                @test serialize(tx.outputs[2].scriptpubkey) == want
            end
        end
        @testset "Segwit" begin
            tx = Tx(IOBuffer(raw_bip141))
            @test tx.version == 0x00000001
            @test tx.flag == 0x01
            hex1 = "3045022100df7b7e5cda14ddf91290e02ea10786e03eb11ee36ec02dd862fe9a326bbcb7fd02203f5b4496b667e6e281cc654a2da9e4f08660c620a1051337fa8965f727eb191901"
            hex2 = "038262a6c6cec93c2d3ecd6c6072efea86d02ff8e3328bbd0242b20af3425990ac"
            @test tx.witnesses[1].data[1] == hex2bytes(hex1)
            @test tx.witnesses[1].data[2] == hex2bytes(hex2)
        end
    end
    @testset "Serialize" begin
        tx = Tx(IOBuffer(raw_tx))
        @test serialize(tx) == raw_tx

        tx = Tx(IOBuffer(raw_bip141))
        @test serialize(tx) == raw_bip141
    end
    @testset "Is CoinbaseTx" begin
        raw_tx = hex2bytes("01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff5e03d71b07254d696e656420627920416e74506f6f6c20626a31312f4542312f4144362f43205914293101fabe6d6d678e2c8c34afc36896e7d9402824ed38e856676ee94bfdb0c6c4bcd8b2e5666a0400000000000000c7270000a5e00e00ffffffff01faf20b58000000001976a914338c84849423992471bffb1a54a8d9b1d69dc28a88ac00000000")
        stream = IOBuffer(raw_tx)
        tx = Tx(stream)
        @test iscoinbase(tx)
    end
    @testset "coinbase_height" begin
        raw_tx = hex2bytes("01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff5e03d71b07254d696e656420627920416e74506f6f6c20626a31312f4542312f4144362f43205914293101fabe6d6d678e2c8c34afc36896e7d9402824ed38e856676ee94bfdb0c6c4bcd8b2e5666a0400000000000000c7270000a5e00e00ffffffff01faf20b58000000001976a914338c84849423992471bffb1a54a8d9b1d69dc28a88ac00000000")
        stream = IOBuffer(raw_tx)
        tx = Tx(stream)
        @test coinbase_height(tx) == 465879
        raw_tx = hex2bytes("0100000001813f79011acb80925dfe69b3def355fe914bd1d96a3f5f71bf8303c6a989c7d1000000006b483045022100ed81ff192e75a3fd2304004dcadb746fa5e24c5031ccfcf21320b0277457c98f02207a986d955c6e0cb35d446a89d3f56100f4d7f67801c31967743a9c8e10615bed01210349fc4e631e3624a545de3f89f5d8684c7b8138bd94bdd531d2e213bf016b278afeffffff02a135ef01000000001976a914bc3b654dca7e56b04dca18f2566cdaf02e8d9ada88ac99c39800000000001976a9141c4bc762dd5423e332166702cb75f40df79fea1288ac19430600")
        stream = IOBuffer(raw_tx)
        tx = Tx(stream)
        @test_throws AssertionError coinbase_height(tx)
    end
end
