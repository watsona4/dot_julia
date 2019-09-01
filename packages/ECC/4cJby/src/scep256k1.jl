# scep256k1 constants
A = 0
B = 7
P = big(2)^256 - 2^32 - 977
N = big"0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141"

"Element in an scep256k1 field"
struct S256Element <: PrimeField
     𝑛::BigInt
     𝑝::BigInt
     S256Element(𝑛,𝑝=P) = !infield(𝑛,𝑝) ? throw(DomainError("𝑛 is not in field range")) : new(𝑛,𝑝)
end

S256Element(x::S256Element) = x

"Formats S256Element showing 𝑛 in hexadecimal format"
function show(io::IO, z::S256Element)
    print(io, string(z.𝑛, base = 16),"\n(in scep256k1 field)")
end

"Returns the square root of an S256Element"
function sqrt(𝑃::S256Element)
    return 𝑃^fld(ECC.P + 1, 4)
end

A = S256Element(A)
B = S256Element(B)

"""
    S256Point{T<:Number}

S256Point(𝑥::T, 𝑦::T) where {T<:Union{S256FieldElement, Integer, Infinity}}
represents a point in an scep256k1 field.
"""
struct S256Point{T<:Number} <: AbstractPoint
    𝑥::T
    𝑦::T
    𝑎::S256Element
    𝑏::S256Element
    S256Point{T}(𝑥,𝑦,𝑎=A,𝑏=B) where {T<:Number} = new(𝑥,𝑦,𝑎,𝑏)
end

S256Point(::Infinity,::Infinity) = S256Point{Infinity}(∞,∞)
S256Point(𝑥::S256Element,𝑦::S256Element) = !iselliptic(𝑥,𝑦,A,B) ? throw(DomainError("Point is not on curve")) : S256Point{S256Element}(𝑥,𝑦)
S256Point(x::Integer,y::Integer) = S256Point{S256Element}(S256Element(big(x)),S256Element(big(y)))

"Formats S256Point as (𝑥, 𝑦) in hexadecimal format"
function show(io::IO, z::S256Point)
    if typeof(z.𝑥) <: PrimeField
        x, y = z.𝑥.𝑛, z.𝑦.𝑛
    else
        x, y = z.𝑥, z.𝑦
    end
    print(io, "scep256k1 Point(𝑥,𝑦):\n", string(x, base = 16), ",\n", string(y, base = 16))
end

"Compares two S256Point, returns true if coordinates are equal"
==(x::S256Point, y::S256Point) = x.𝑥 == y.𝑥 && x.𝑦 == y.𝑦

"Scalar multiplication of an S256Point"
function *(λ::Integer,𝑃::S256Point)
    𝑅 = S256Point(∞, ∞)
    λ =  mod(λ, N)
    while λ > 0
        if λ & 1 != 0
            𝑅 += 𝑃
        end
        𝑃 += 𝑃
        λ >>= 1
    end
    return 𝑅
end

"""
Serialize an S256Point() to compressed SEC format, uncompressed if false is set
as second argument.

'point2sec(P::T, compressed::Bool=true) where {T<:S256Point} -> Array{UInt8,1}'
"""
function point2sec(P::T, compressed::Bool=true) where {T<:S256Point}
    xbin = int2bytes(P.𝑥.𝑛)
    if compressed
        if mod(P.𝑦.𝑛, 2) == 0
            prefix = 0x02
        else
            prefix = 0x03
        end
        return cat(prefix,xbin;dims=1)
    else
        return cat(0x04,xbin,int2bytes(P.𝑦.𝑛);dims=1)
    end
end

"""
Parse a SEC binary to an S256Point()

sec2point(sec_bin::AbstractArray{UInt8}) -> S256Point
"""
function sec2point(sec_bin::AbstractArray{UInt8})
    if sec_bin[1] == 4
        𝑥 = bytes2int(sec_bin[2:33])
        𝑦 = bytes2int(sec_bin[34:65])
        return S256Point(𝑥, 𝑦)
    end
    is_even = sec_bin[1] == 2
    𝑥 = ECC.S256Element(bytes2int(sec_bin[2:end]))
    α = 𝑥^3 + ECC.S256Element(ECC.B)
    β = sqrt(α)
    if mod(β.𝑛, 2) == 0
        evenβ = β
        oddβ = S256Element(ECC.P - β.𝑛)
    else
        evenβ = S256Element(ECC.P - β.𝑛)
        oddβ = β
    end
    if is_even
        return S256Point(𝑥, evenβ)
    else
        return S256Point(𝑥, oddβ)
    end
end

"""
Returns true if Signature is valid for 𝑧 given 𝑃, false if not

verify(𝑃::AbstractPoint, 𝑧::Integer, sig::Signature) -> Bool
"""
function verify(𝑃::AbstractPoint,𝑧::Integer,sig::Signature)
    𝑠⁻¹ = powermod(sig.𝑠, N - 2, N)
    𝑢 = mod(𝑧 * 𝑠⁻¹, N)
    𝑣 = mod(sig.𝑟 * 𝑠⁻¹, N)
    𝑅 = 𝑢 * G + 𝑣 * 𝑃
    return 𝑅.𝑥.𝑛 == sig.𝑟
end

# scep256k1 generator point
G = S256Point(big"0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798",
              big"0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8")
