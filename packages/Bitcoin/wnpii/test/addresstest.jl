@testset "Bitcoin address functions" begin
        @testset "address" begin
                secret = 888^3
                mainnet_address = "148dY81A9BmdpMhvYEVznrM45kWN32vSCN"
                testnet_address = "mieaqB68xDCtbUBYFoUNcmZNwk74xcBfTP"
                point = secret * Secp256k1.G
                @test point2address(point, true, false) == mainnet_address
                @test point2address(point, true, true) == testnet_address
                secret = 321
                mainnet_address = "1S6g2xBJSED7Qr9CYZib5f4PYVhHZiVfj"
                testnet_address = "mfx3y63A7TfTtXKkv7Y6QzsPFY6QCBCXiP"
                point = secret * Secp256k1.G
                @test point2address(point, false, false) == mainnet_address
                @test point2address(point, false, true) == testnet_address
                secret = 4242424242
                mainnet_address = "1226JSptcStqn4Yq9aAmNXdwdc2ixuH9nb"
                testnet_address = "mgY3bVusRUL6ZB2Ss999CSrGVbdRwVpM8s"
                point = secret * Secp256k1.G
                @test point2address(point, false, false) == mainnet_address
                @test point2address(point, false, true) == testnet_address
                @testset "P2PKH" begin
                        h160 = hex2bytes("74d691da1574e6b3c192ecfb52cc8984ee7b6c56")
                        want = "1BenRpVUFK65JFWcQSuHnJKzc4M8ZP8Eqa"
                        @test h160_2_address(h160, false, "P2PKH") == want
                        want = "mrAjisaT4LXL5MzE81sfcDYKU3wqWSvf9q"
                        @test h160_2_address(h160, true, "P2PKH") == want
                end
                @testset "P2SH" begin
                        h160 = hex2bytes("74d691da1574e6b3c192ecfb52cc8984ee7b6c56")
                        want = "3CLoMMyuoDQTPRD3XYZtCvgvkadrAdvdXh"
                        @test h160_2_address(h160, false, "P2SH") == want
                        want = "2N3u1R6uwQfuobCqbCgBkpsgBxvr1tZpe7B"
                        @test h160_2_address(h160, true, "P2SH") == want
                end
        end
        @testset "WIF" begin
                kp = KeyPair{:ECDSA}(big(2)^256-big(2)^199)
                expected = "L5oLkpV3aqBJ4BgssVAsax1iRa77G5CVYnv9adQ6Z87te7TyUdSC"
                @test wif(kp, true, false) == expected
                kp = KeyPair{:ECDSA}(big(2)^256-big(2)^201)
                expected = "93XfLeifX7Jx7n7ELGMAf1SUR6f9kgQs8Xke8WStMwUtrDucMzn"
                @test wif(kp, false, true) == expected
                kp = KeyPair{:ECDSA}(big"0x0dba685b4511dbd3d368e5c4358a1277de9486447af7b3604a69b8d9d8b7889d")
                expected = "5HvLFPDVgFZRK9cd4C5jcWki5Skz6fmKqi1GQJf5ZoMofid2Dty"
                @test wif(kp, false, false) == expected
                kp = KeyPair{:ECDSA}(big"0x1cca23de92fd1862fb5b76e5f4f50eb082165e5191e116c18ed1a6b24be6a53f")
                expected = "cNYfWuhDpbNM1JWc3c6JTrtrFVxU4AGhUKgw5f93NP2QaBqmxKkg"
                @test wif(kp, true, true) == expected
        end
end
