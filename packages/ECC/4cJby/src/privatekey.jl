"""
PrivateKey(𝑒) represents an S256Point determined by 𝑃 = 𝑒G,
where 𝑒 is an integer and G the scep256k1 generator point.
"""
struct PrivateKey
    𝑒::Integer
    𝑃::AbstractPoint
    PrivateKey(𝑒) = new(𝑒, 𝑒 * G)
end

"""
Returns a Signature for a given PrivateKey and data 𝑧
pksign(pk::PrivateKey, 𝑧::Integer) -> Signature
"""
function pksign(pk::PrivateKey, 𝑧::Integer)
    𝑘 = rand(big.(0:N))
    𝑟 = (𝑘 * G).𝑥.𝑛
    𝑘⁻¹ = powermod(𝑘, N - 2, N)
    𝑠 = mod((𝑧 + 𝑟 * pk.𝑒) * 𝑘⁻¹, N)
    if 𝑠 > N / 2
        𝑠 = N - 𝑠
    end
    return Signature(𝑟, 𝑠)
end
