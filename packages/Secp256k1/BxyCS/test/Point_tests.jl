@testset "Point Operations" begin

    import Secp256k1: Infinity, Point, NotOnCurve, 𝐹, G

    points = (
        Point(𝐹(big"0xa2d3161994ca49dba5f6a26d8b19d37b00cca173e73a78fa1944e1456b4bf99c"),
              𝐹(big"0x5da5a4f7198635acaadc75141fa096e0606a17e819743456a33f1fe185dfb7a9")),
        Point(𝐹(big"0x4bd9529fd874db685c9252657a389ffdc75602f66abbd37d0a31eb693a918ea"),
              𝐹(big"0x7748d379a9da6ba667bcda3052a6a368e787a72fdf2664ca3933fc8d5fd01167")),
        Point(𝐹(big"0xf13e238add1d7981c3f466f8a3c20500538bd15d822b3e8474bb790be17da072"),
              𝐹(big"0x5b76f0a236fba0234a208522ecbe7f3ce4f537a42885ee466f7eca6e1d2d5cbc"))
    )

    @testset "On curve?" begin
        invalid_points = ((200, 119), (42, 99))
        for 𝑃 ∈ invalid_points
            @test_throws NotOnCurve Point(𝑃[1], 𝑃[2])
        end
    end

    @testset "Addition" begin
        want = (
            Point(𝐹(big"0xb2c90a144ac8d9f1ef3b006966fae31fd309f1cad77c8e1eeba97066618de0ba"),
                  𝐹(big"0xd94824954468c2c9261c1e021d3c30a038f4528d5da85ff416b40185a891aa95")),
            Point(𝐹(big"0x74399cab4b7dabf48414e65528b4bfbacd83afc5762856fbaf3c37453ab587b8"),
                  𝐹(big"0x7bbc7eb7482b57783f496ecdcf07f2b25ac28b4bc76e5ec3976b7026c385407b")),
            Point(𝐹(big"0x3a4a73aa1176eb1ff4356e661bffc4030f02fbebd90e03d6eb9a8c2ebff0f199"),
                  𝐹(big"0xda3d13611988ebfb288a06561ab0addc8fccee33f1df7b9242fc44a7c3e64e03"))
        )

        @test points[1] + points[2] == want[1]
        @test points[1] + points[3] == want[2]
        @test points[2] + points[3] == want[3]
    end

    @testset "Scalar Multiplication" begin
        @test Secp256k1.N * Secp256k1.G == Point{Infinity}(∞, ∞)
        scalars = (1, 4 , 832)
        want = (
            Point(𝐹(big"0xa2d3161994ca49dba5f6a26d8b19d37b00cca173e73a78fa1944e1456b4bf99c"),
                  𝐹(big"0x5da5a4f7198635acaadc75141fa096e0606a17e819743456a33f1fe185dfb7a9")),
            Point(𝐹(big"0xd4d85a3f5562fc262365cf78103e5f5ba0ef3d64918ea2063747ae541bd2030f"),
                  𝐹(big"0xb5512fb7bc50c34f7029f5a87c8ea46bd7a2ea14c6ec1c6bffed28f8252f7492")),
            Point(𝐹(big"0xc49e8f1f66265158c48b65e26fb4e65b1802830134b544be62934d0c1fec1ef3"),
                  𝐹(big"0xc23915cfc9adc4871d5d84ad0d8363f138593ca918ae1c8c5ace312d3afc99e6"))
        )
        for i in 1:3
            @test scalars[i] * points[i] == want[i]
        end
    end

    @testset "Parse" begin
        sec_bin = hex2bytes("0349fc4e631e3624a545de3f89f5d8684c7b8138bd94bdd531d2e213bf016b278a")
        point = Secp256k1.Point(sec_bin)
        want = big"0xa56c896489c71dfc65701ce25050f542f336893fb8cd15f4e8e5c124dbf58e47"
        @test point.𝑦.𝑛 == want
        sec_bin = hex2bytes("049d5ca49670cbe4c3bfa84c96a8c87df086c6ea6a24ba6b809c9de234496808d56fa15cc7f3d38cda98dee2419f415b7513dde1301f8643cd9245aea7f3f911f9")
        point = Secp256k1.Point(sec_bin)
        want = big"0x6fa15cc7f3d38cda98dee2419f415b7513dde1301f8643cd9245aea7f3f911f9"
        @test point.𝑦.𝑛 == want
    end

    @testset "Serialize" begin
        coefficient = 999^3
        uncompressed = "049d5ca49670cbe4c3bfa84c96a8c87df086c6ea6a24ba6b809c9de234496808d56fa15cc7f3d38cda98dee2419f415b7513dde1301f8643cd9245aea7f3f911f9"
        compressed = "039d5ca49670cbe4c3bfa84c96a8c87df086c6ea6a24ba6b809c9de234496808d5"
        point = coefficient * G
        @test Secp256k1.serialize(point, compressed=false) == hex2bytes(uncompressed)
        @test Secp256k1.serialize(point, compressed=true)  == hex2bytes(compressed)

        coefficient = 123
        uncompressed = "04a598a8030da6d86c6bc7f2f5144ea549d28211ea58faa70ebf4c1e665c1fe9b5204b5d6f84822c307e4b4a7140737aec23fc63b65b35f86a10026dbd2d864e6b"
        compressed = "03a598a8030da6d86c6bc7f2f5144ea549d28211ea58faa70ebf4c1e665c1fe9b5"
        point = coefficient * G
        @test Secp256k1.serialize(point, compressed=false) == hex2bytes(uncompressed)
        @test Secp256k1.serialize(point, compressed=true)  == hex2bytes(compressed)

        coefficient = 42424242
        uncompressed = "04aee2e7d843f7430097859e2bc603abcc3274ff8169c1a469fee0f20614066f8e21ec53f40efac47ac1c5211b2123527e0e9b57ede790c4da1e72c91fb7da54a3"
        compressed = "03aee2e7d843f7430097859e2bc603abcc3274ff8169c1a469fee0f20614066f8e"
        point = coefficient * G
        @test Secp256k1.serialize(point, compressed=false) == hex2bytes(uncompressed)
        @test Secp256k1.serialize(point, compressed=true)  == hex2bytes(compressed)

        want = hex2bytes("02000000000005689111130e588a12ecda87b2dc5585c6c6ba66a412fa0cce65bc")
        point = Point(big"0x5689111130e588a12ecda87b2dc5585c6c6ba66a412fa0cce65bc",
                      big"0x9153b93a0c3b37a18b483b45f36c8a9c1c7deb468202eff9423318bfb9660f12")
        @test Secp256k1.serialize(point) == want
    end
end
