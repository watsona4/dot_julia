@testset "ECC Tests" begin

    @testset "DER Signature Parsing and Serialization" begin
        @testset "der2sig" begin
            der = hex2bytes("304402201f62993ee03fca342fcb45929993fa6ee885e00ddad8de154f268d98f083991402201e1ca12ad140c04e0e022c38f7ce31da426b8009d02832f0b44f39a6b178b7a1")
            sig = Signature(parse(BigInt, "1f62993ee03fca342fcb45929993fa6ee885e00ddad8de154f268d98f0839914", base=16),
                            parse(BigInt, "1e1ca12ad140c04e0e022c38f7ce31da426b8009d02832f0b44f39a6b178b7a1", base=16))
            @test der2sig(der) == sig
        end
        @testset "sig2der" begin
            testcases = (
                (1, 2),
                (rand(big.(0:big(2)^255)), rand(big.(0:big(2)^255))),
                (rand(big.(0:big(2)^255)), rand(big.(0:big(2)^255))),
                (rand(big.(0:big(2)^255)), rand(big.(0:big(2)^223))))
            for x in testcases
                sig = Signature(x[1], x[2])
                der = sig2der(sig)
                sig2 = der2sig(der)
                @test sig2 == sig
            end
        end
    end

    @testset "Signature Verification" begin
        pk = PrivateKey(rand(big.(0:big(2)^256)))
        𝑧 = rand(big.(0:big(2)^256))
        𝑠 = pksign(pk, 𝑧)
        @test verify(pk.𝑃, 𝑧, 𝑠)
    end

    @testset "scep256k1" begin

        @testset "Order" begin
            point = ECC.N * ECC.G
            @test typeof(point) == S256Point{ECC.Infinity}
        end

        @testset "Public Point" begin
            points = (
                # secret, x, y
                (7, big"0x5cbdf0646e5db4eaa398f365f2ea7a0e3d419b7e0330e39ce92bddedcac4f9bc", big"0x6aebca40ba255960a3178d6d861a54dba813d0b813fde7b5a5082628087264da"),
                (1485, big"0xc982196a7466fbbbb0e27a940b6af926c1a74d5ad07128c82824a11b5398afda", big"0x7a91f9eae64438afb9ce6448a1c133db2d8fb9254e4546b6f001637d50901f55"),
                (big(2)^128, big"0x8f68b9d2f63b5f339239c1ad981f162ee88c5678723ea3351b7b444c9ec4c0da", big"0x662a9f2dba063986de1d90c2b6be215dbbea2cfe95510bfdf23cbf79501fff82"),
                (big(2)^240 + 2^31, big"0x9577ff57c8234558f293df502ca4f09cbc65a6572c842b39b366f21717945116", big"0x10b49c67fa9365ad7b90dab070be339a1daf9052373ec30ffae4f72d5e66d053"),
            )

            for n ∈ points
                point = S256Point(n[2], n[3])
                @test n[1] * ECC.G == point
            end
        end

        @testset "point2sec" begin
            coefficient = 999^3
            uncompressed = "049d5ca49670cbe4c3bfa84c96a8c87df086c6ea6a24ba6b809c9de234496808d56fa15cc7f3d38cda98dee2419f415b7513dde1301f8643cd9245aea7f3f911f9"
            compressed = "039d5ca49670cbe4c3bfa84c96a8c87df086c6ea6a24ba6b809c9de234496808d5"
            point = coefficient * ECC.G
            @test point2sec(point,false) == hex2bytes(uncompressed)
            @test point2sec(point,true) == hex2bytes(compressed)
            coefficient = 123
            uncompressed = "04a598a8030da6d86c6bc7f2f5144ea549d28211ea58faa70ebf4c1e665c1fe9b5204b5d6f84822c307e4b4a7140737aec23fc63b65b35f86a10026dbd2d864e6b"
            compressed = "03a598a8030da6d86c6bc7f2f5144ea549d28211ea58faa70ebf4c1e665c1fe9b5"
            point = coefficient * ECC.G
            @test point2sec(point,false) == hex2bytes(uncompressed)
            @test point2sec(point,true) == hex2bytes(compressed)
            coefficient = 42424242
            uncompressed = "04aee2e7d843f7430097859e2bc603abcc3274ff8169c1a469fee0f20614066f8e21ec53f40efac47ac1c5211b2123527e0e9b57ede790c4da1e72c91fb7da54a3"
            compressed = "03aee2e7d843f7430097859e2bc603abcc3274ff8169c1a469fee0f20614066f8e"
            point = coefficient * ECC.G
            @test point2sec(point,false) == hex2bytes(uncompressed)
            @test point2sec(point,true) == hex2bytes(compressed)
        end

        @testset "sec2point" begin
            sec_bin = hex2bytes("0349fc4e631e3624a545de3f89f5d8684c7b8138bd94bdd531d2e213bf016b278a")
            point = sec2point(sec_bin)
            want = big"0xa56c896489c71dfc65701ce25050f542f336893fb8cd15f4e8e5c124dbf58e47"
            @test point.𝑦.𝑛 == want
            sec_bin = hex2bytes("049d5ca49670cbe4c3bfa84c96a8c87df086c6ea6a24ba6b809c9de234496808d56fa15cc7f3d38cda98dee2419f415b7513dde1301f8643cd9245aea7f3f911f9")
            point = sec2point(sec_bin)
            want = parse(BigInt, "6fa15cc7f3d38cda98dee2419f415b7513dde1301f8643cd9245aea7f3f911f9", base=16)
            @test point.𝑦.𝑛 == want
        end

        @testset "Signature Verification" begin
            point = S256Point(
                big"0x887387e452b8eacc4acfde10d9aaf7f6d9a0f975aabb10d006e4da568744d06c",
                big"0x61de6d95231cd89026e286df3b6ae4a894a3378e393e93a0f45b666329a0ae34")
            z = big"0xec208baa0fc1c19f708a9ca96fdeff3ac3f230bb4a7ba4aede4942ad003c0f60"
            r = big"0xac8d1c87e51d0d441be8b3dd5b05c8795b48875dffe00b7ffcfac23010d3a395"
            s = big"0x68342ceff8935ededd102dd876ffd6ba72d6a427a3edb13d26eb0781cb423c4"
            @test verify(point, z, Signature(r, s))
            z = big"0x7c076ff316692a3d7eb3c3bb0f8b1488cf72e1afcd929e29307032997a838a3d"
            r = big"0xeff69ef2b1bd93a66ed5219add4fb51e11a840f404876325a1e8ffe0529a2c"
            s = big"0xc7207fee197d27c618aea621406f6bf5ef6fca38681d82b2f06fddbdce6feab6"
            @test verify(point, z, Signature(r, s))
        end
    end

end
