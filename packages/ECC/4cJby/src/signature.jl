"""
Signature(𝑟, 𝑠) represents a Signature for 𝑧 in which
```𝑠 = (𝑧 + 𝑟𝑒) / 𝑘```
𝑘 being a random integer.
"""
struct Signature
    𝑟::BigInt
    𝑠::BigInt
    Signature(𝑟, 𝑠) = new(𝑟, 𝑠)
end

"Formats Signature as (r, s) in hexadecimal format"
function show(io::IO, z::Signature)
    print(io, "scep256k1 signature(𝑟, 𝑠):\n", string(z.𝑟, base = 16), ",\n", string(z.𝑠, base = 16))
end

==(x::Signature, y::Signature) = x.𝑟 == y.𝑟 && x.𝑠 == y.𝑠

"""
Serialize a Signature to DER format

sig2der(x::Signature) -> Array{UInt8,1}
"""
function sig2der(x::Signature)
    rbin = int2bytes(x.𝑟)
    # if rbin has a high bit, add a 00
    if rbin[1] >= 128
        rbin = pushfirst!(rbin, 0x00)
    end
    result = cat([0x02], int2bytes(length(rbin)), rbin; dims=1)
    sbin = int2bytes(x.𝑠)
    # if sbin has a high bit, add a 00
    if sbin[1] >= 128
        sbin = pushfirst!(sbin, 0x00)
    end
    result = cat(result, [0x02], int2bytes(length(sbin)), sbin; dims=1)
    return cat([0x30], int2bytes(length(result)), result; dims=1)
end

"""
Parse a DER binary to a Signature

der2sig(signature_bin::AbstractArray{UInt8}) -> Signature
"""
function der2sig(signature_bin::AbstractArray{UInt8})
    s = IOBuffer(signature_bin)
    bytes = UInt8[]
    readbytes!(s, bytes, 1)
    if bytes[1] != 0x30
        throw(DomainError("Bad Signature"))
    end
    readbytes!(s, bytes, 1)
    if bytes[1] + 2 != length(signature_bin)
        throw(DomainError("Bad Signature Length"))
    end
    readbytes!(s, bytes, 1)
    if bytes[1] != 0x02
        throw(DomainError("Bad Signature"))
    end
    readbytes!(s, bytes, 1)
    rlength = Int(bytes[1])
    readbytes!(s, bytes, rlength)
    r = bytes2hex(bytes)
    readbytes!(s, bytes, 1)
    if bytes[1] != 0x02
        throw(DomainError("Bad Signature"))
    end
    readbytes!(s, bytes, 1)
    slength = Int(bytes[1])
    bytes = UInt8[]
    readbytes!(s, bytes, slength)
    s = bytes2hex(bytes)
    if length(signature_bin) != 6 + rlength + slength
        throw(DomainError("Signature too long"))
    end
    return Signature(parse(BigInt, r, base=16),
                     parse(BigInt, s, base=16))
end
