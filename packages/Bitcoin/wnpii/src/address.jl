"""
    Vector{UInt8} -> String

Returns a String representing a Bitcoin address
"""
function h160_2_address(h160::Vector{UInt8}, testnet::Bool=false, type::String="P2SH")
    testnet ? i = 1 : i = 2
    result = copy(h160)
    result = pushfirst!(result, SCRIPT_TYPES[type][i])
    return String(base58checkencode(result))
end

"""
    point2address(P::Secp256k1.Point, compressed::Bool, testnet::Bool) -> String

Returns the Base58 Bitcoin address given an Secp256k1.Point
Compressed is set to true if not provided.
Testnet is set to false by default.
"""
function point2address(P::T, compressed::Bool=true, testnet::Bool=false, type::String="P2PKH") where {T<:Secp256k1.Point}
    s = serialize(P, compressed=compressed)
    h160 = ripemd160(sha256(s))
    return h160_2_address(h160, testnet, type)
end

"""
    wif(kp::KeyPair, compressed::Bool=true, testnet::Bool=false) -> String

Returns a KeyPair in Wallet Import Format
Compressed is set to true if not provided.
Testnet is set to false by default.
"""
function wif(kp::KeyPair, compressed::Bool=true, testnet::Bool=false)
    secret_bytes = bytes(kp.𝑑)
    if testnet
        prefix = 0xef
    else
        prefix = 0x80
    end
    result = pushfirst!(secret_bytes, prefix)
    if compressed
        return String(base58checkencode(push!(result, 0x01)))
    else
        return String(base58checkencode(result))
    end
end

@deprecate address(P::T, compressed::Bool, testnet::Bool)  where {T<:Secp256k1.Point} point2address(P::T, compressed::Bool, testnet::Bool, type::String)  where {T<:Secp256k1.Point}
