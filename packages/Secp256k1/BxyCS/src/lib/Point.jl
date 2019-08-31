const A = 𝐹(0)
const B = 𝐹(7)

oncurve(𝑥::FieldElement,𝑦::FieldElement) = 𝑦^2 == 𝑥^3 + A*𝑥 + B

xField = Union{FieldElement, Infinity}

"""
    Point{T<:xField}

`Point{T<:xField}(𝑥::T, 𝑦::T)` represents a point in an scep256k1 field.
`xField` is equal to `Union{FieldElement, Infinity}`
"""
struct Point{T<:xField}
    𝑥::T
    𝑦::T
end

Point(::Infinity,::Infinity) = Point{Infinity}(∞,∞)
Point(𝑥::FieldElement,𝑦::FieldElement) = !oncurve(𝑥,𝑦) ? throw(NotOnCurve()) : Point{FieldElement}(𝑥,𝑦)
Point(𝑥::Integer,𝑦::Integer) = !oncurve(𝐹(𝑥),𝐹(𝑦)) ? throw(NotOnCurve()) : Point{FieldElement}(𝐹(𝑥),𝐹(𝑦))

const G = Point(big"0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798",
                big"0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8")

"Formats Point{FieldElement} as `(𝑥, 𝑦)` in hexadecimal format"
function show(io::IO, z::Point{FieldElement})
    x, y = z.𝑥.𝑛, z.𝑦.𝑛
    print(io, "scep256k1 Point(𝑥,𝑦):\n", string(x, base = 16), ",\n", string(y, base = 16))
end

"Formats Point{Infinity} as `(∞, ∞)`"
function show(io::IO, z::Point{Infinity})
    print(io, "scep256k1 Point(∞, ∞)")
end

"Compares two Point, returns true if coordinates are equal"
==(x::Point, y::Point) = x.𝑥 == y.𝑥 && x.𝑦 == y.𝑦

"""
Returns the point resulting from the intersection of the curve and the
straight line defined by the points P and Q
"""
function +(𝑃::Point,𝑄::Point)
    if 𝑃.𝑥 == ∞
        return 𝑄
    elseif 𝑄.𝑥 == ∞
        return 𝑃
    elseif 𝑃.𝑥 == 𝑄.𝑥 && 𝑃.𝑦 != 𝑄.𝑦
        Point{Infinity}(∞, ∞)

    # Case 1
    elseif 𝑃.𝑥 != 𝑄.𝑥
        λ = (𝑄.𝑦 - 𝑃.𝑦) ÷ (𝑄.𝑥 - 𝑃.𝑥)
        𝑥 = λ^2 - 𝑃.𝑥 - 𝑄.𝑥
    # Case 2
    else
        λ = (3 * 𝑃.𝑥^2 + A) ÷ (2 * 𝑃.𝑦)
        𝑥 = λ^2 - 2 * 𝑃.𝑥
    end
    𝑦 = λ * (𝑃.𝑥 - 𝑥) - 𝑃.𝑦
    return Point{FieldElement}(𝑥, 𝑦)
end

"Scalar multiplication of an Point"
function *(λ::Integer,𝑃::Point)
    𝑅 = Point(∞, ∞)
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
    serialize(P::Point; compressed::Bool) -> Vector{UInt8}

Serialize a `Point` to its SEC format
- `compressed=true` by default
"""
function serialize(P::Point; compressed::Bool=true)
    xbin = bytes(P.𝑥.𝑛)
    if length(xbin) < 32
        prepend!(xbin, UInt8.(zeros(32 - length(xbin))))
    end
    if compressed
        if mod(P.𝑦.𝑛, 2) == 0
            prefix = 0x02
        else
            prefix = 0x03
        end
        return pushfirst!(xbin,prefix)
    else
        pushfirst!(xbin, 0x04)
        ybin = bytes(P.𝑦.𝑛)
        if length(ybin) < 32
            prepend!(ybin, UInt8.(zeros(32 - length(ybin))))
        end
        return append!(xbin, ybin)
    end
end

"""
    Point(io::IOBuffer) -> Point

Parse a SEC binary to an `Point`
"""
function Point(io::IOBuffer)
    prefix = read(io, 1)[1]
    if prefix == 4
        𝑥 = to_int(read(io, 32))
        𝑦 = to_int(read(io, 32))
        return Point(𝑥, 𝑦)
    end
    is_even = prefix == 2
    𝑥 = 𝐹(to_int(read(io, 32)))
    α = 𝑥^3 + 𝐹(B)
    β = sqrt(α)
    if mod(β.𝑛, 2) == 0
        evenβ = β
        oddβ = 𝐹(P - β.𝑛)
    else
        evenβ = 𝐹(P - β.𝑛)
        oddβ = β
    end
    if is_even
        return Point(𝑥, evenβ)
    else
        return Point(𝑥, oddβ)
    end
end

Point(sec::Vector{UInt8}) = Point(IOBuffer(sec))
