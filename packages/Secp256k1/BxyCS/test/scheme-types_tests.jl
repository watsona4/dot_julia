@testset "Scheme Types" begin
    @testset "Parse" begin
        der = hex2bytes("304402201f62993ee03fca342fcb45929993fa6ee885e00ddad8de154f268d98f083991402201e1ca12ad140c04e0e022c38f7ce31da426b8009d02832f0b44f39a6b178b7a1")
        sig = Signature{:ECDSA}(big"0x1f62993ee03fca342fcb45929993fa6ee885e00ddad8de154f268d98f0839914",
                                big"0x1e1ca12ad140c04e0e022c38f7ce31da426b8009d02832f0b44f39a6b178b7a1")
        @test Secp256k1.Signature(der) == sig
    end
    @testset "Serialize" begin
        testcases = (
            (1, 2),
            (rand(big.(0:big(2)^255)), rand(big.(0:big(2)^255))),
            (rand(big.(0:big(2)^255)), rand(big.(0:big(2)^255))),
            (rand(big.(0:big(2)^255)), rand(big.(0:big(2)^223))))
        for x in testcases
            sig  = Signature{:ECDSA}(x[1], x[2])
            der  = Secp256k1.serialize(sig)
            sig2 = Secp256k1.Signature(der)
            @test sig2 == sig
        end
    end
end
