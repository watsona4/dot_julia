"""
`KeyPair{T}(𝑑::BigInt, 𝑄::Point)` represents a private-public key pair in which
- `𝑑` is the secret key
- `𝑄` the public key
= `T` represents key pair scheme

`KeyPair{:ECDSA}(𝑑::Integer)` instantiate a `KeyPair` such as 𝑄 = 𝑑𝐺 and where
- {𝑑 ∈ ℤ | 𝑑 < 𝑛}
- 𝐺 is the secp256k1 base point.
- 𝑛 is the order of 𝐺
"""
struct KeyPair{T}
    𝑑::BigInt
    𝑄::Point
end

"""
Signature{T}(𝑟::BigInt, 𝑠::BigInt) represents a following scheme `T`
- `T` can be set to `:ECDSA`
"""
struct Signature{T}
    𝑟::BigInt
    𝑠::BigInt
end

"Formats Signature as (r, s) in hexadecimal format"
function show(io::IO, z::Signature)
    print(io, "scep256k1 signature(𝑟, 𝑠):\n", string(z.𝑟, base = 16), ",\n", string(z.𝑠, base = 16))
end

==(x::Signature, y::Signature) = x.𝑟 == y.𝑟 && x.𝑠 == y.𝑠


"""
    serialize(x::Signature) -> Vector{UInt8}

Serialize a `Signature` to DER format
"""
function serialize(x::Signature)
    rbin = bytes(x.𝑟)
    # if rbin has a high bit, add a 00
    if rbin[1] >= 128
        rbin = pushfirst!(rbin, 0x00)
    end
    prepend!(rbin, bytes(length(rbin)))
    pushfirst!(rbin, 0x02)

    sbin = bytes(x.𝑠)
    # if sbin has a high bit, add a 00
    if sbin[1] >= 128
        sbin = pushfirst!(sbin, 0x00)
    end
    prepend!(sbin, bytes(length(sbin)))
    pushfirst!(sbin, 0x02)

    result = sbin
    prepend!(result, rbin)
    prepend!(result, bytes(length(result)))
    return pushfirst!(result, 0x30)
end

"""
    Signature(x::Vector{UInt8}; scheme::Symbol) -> Signature

Parse a DER binary to a `Signature{scheme}`
- `scheme` is optional and set to `:ECDSA` by default.
"""
function Signature(x::Vector{UInt8}; scheme::Symbol=:ECDSA)
    io = IOBuffer(x)
    prefix = read(io, 1)[1]
    if prefix != 0x30
        throw(PrefixError())
    end
    len = read(io, 1)[1]
    if len + 2 != length(x)
        throw(LengthError())
    end
    prefix = read(io, 1)[1]
    if prefix != 0x02
        throw(PrefixError())
    end
    rlength = read(io, 1)[1]
    r = to_int(read(io, rlength))
    prefix = read(io, 1)[1]
    if prefix != 0x02
        throw(PrefixError())
    end
    slength = read(io, 1)[1]
    s = to_int(read(io, slength))
    if length(x) != 6 + rlength + slength
        throw(LengthError())
    end
    return Signature{scheme}(r, s)
end
