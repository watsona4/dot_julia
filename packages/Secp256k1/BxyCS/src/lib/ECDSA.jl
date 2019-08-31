module ECDSA

using BitConverter
using Secp256k1: Point, KeyPair, Signature, N, G
export KeyPair

KeyPair{:ECDSA}(𝑑::Integer) = 𝑑 ∉ 1:N-1 ? throw(NotInField()) : KeyPair{:ECDSA}(𝑑, 𝑑 * G)

"""
    ECDSA.sign(kp::KeyPair{:ECDSA}, 𝑧::Integer) -> Signature{:ECDSA}

Returns a Signature{:ECDSA} for a given `KeyPair{:ECDSA}` and data `𝑧` and in
which 𝑠 = (𝑧 + 𝑟𝑑) / 𝑘, 𝑘 being a random integer.
"""
function sign(kp::KeyPair{:ECDSA}, 𝑧::Integer)
    𝑘 = rand(big.(0:N))
    𝑟 = (𝑘 * G).𝑥.𝑛
    𝑘⁻¹ = powermod(𝑘, N - 2, N)
    𝑠 = mod((𝑧 + 𝑟 * kp.𝑑) * 𝑘⁻¹, N)
    if 𝑠 > N / 2
        𝑠 = N - 𝑠
    end
    return Signature{:ECDSA}(𝑟, 𝑠)
end

"""
    verify(𝑄::Point, 𝑧::Integer, sig::Signature{:ECDSA}) -> Bool

Returns true if Signature{:ECDSA} is valid for 𝑧 given 𝑄, false if not
"""
function verify(𝑄::Point, 𝑧::Integer, sig::Signature{:ECDSA})
    𝑠⁻¹ = powermod(sig.𝑠, N - 2, N)
    𝑢 = mod(𝑧 * 𝑠⁻¹, N)
    𝑣 = mod(sig.𝑟 * 𝑠⁻¹, N)
    𝑅 = 𝑢 * G + 𝑣 * 𝑄
    return 𝑅.𝑥.𝑛 == sig.𝑟
end

end  # module ECDSA
