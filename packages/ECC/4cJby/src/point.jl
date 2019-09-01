abstract type AbstractPoint end

function iselliptic(𝑥::Number,𝑦::Number,𝑎::Number,𝑏::Number)
    𝑦^2 == 𝑥^3 + 𝑎*𝑥 + 𝑏
end

POINTTYPES = Union{Integer,PrimeField}

"""
Represents a point with coordinates (𝑥,𝑦) on an elliptic curve where 𝑦² = 𝑥³ + 𝑎𝑥 + 𝑏
Optional parameter 𝑝 represents finite field 𝐹ₚ and will convert all other parameter to PrimeField
Point(∞,∞,𝑎,𝑏) represents point at infinity
Returns an error if elliptic curve equation isn't satisfied
"""
struct Point{T<:Number,S<:Number} <: AbstractPoint
    𝑥::T
    𝑦::T
    𝑎::S
    𝑏::S
    Point{T,S}(𝑥,𝑦,𝑎,𝑏) where {T<:Number,S<:Number} = new(𝑥,𝑦,𝑎,𝑏)
end

Point(𝑥::Infinity,𝑦::Infinity,𝑎::T,𝑏::T) where {T<:POINTTYPES} = Point{Infinity,T}(𝑥,𝑦,𝑎,𝑏)
Point(𝑥::T,𝑦::T,𝑎::T,𝑏::T) where {T<:POINTTYPES} = !iselliptic(𝑥,𝑦,𝑎,𝑏) ? throw(DomainError("Point is not on curve")) : Point{T,T}(𝑥,𝑦,𝑎,𝑏)
Point(𝑥::Infinity,𝑦::Infinity,𝑎::T,𝑏::T,𝑝::T) where {T<:Integer} = Point(𝑥,𝑦,FieldElement(𝑎,𝑝),FieldElement(𝑏,𝑝))
Point(𝑥::T,𝑦::T,𝑎::T,𝑏::T,𝑝::T) where {T<:Integer} = Point(FieldElement(𝑥,𝑝),FieldElement(𝑦,𝑝),FieldElement(𝑎,𝑝),FieldElement(𝑏,𝑝))

"Formats AbstractPoint as (𝑥, 𝑦) on 𝑦² = 𝑥³ + 𝑎𝑥 + 𝑏 (: 𝐹ₚ)"
function show(io::IO, z::AbstractPoint)
    if typeof(z.𝑥) <: PrimeField
        x, y = z.𝑥.𝑛, z.𝑦.𝑛
    else
        x, y = z.𝑥, z.𝑦
    end

    if typeof(z.𝑎) <: PrimeField
        a, b = z.𝑎.𝑛, z.𝑏.𝑛
        field = string(" : 𝐹", z.𝑎.𝑝)
    else
        a, b = z.𝑎, z.𝑏
        field = ""
    end
    print(io, "(", x, ", ", y, ") on 𝑦² = 𝑥³ + ", a, "𝑥 + ", b, field)
end

"""
Returns the point resulting from the intersection of the curve and the
straight line defined by the points P and Q
"""
function +(𝑃::AbstractPoint,𝑄::AbstractPoint)
    T = typeof(𝑃)
    S = typeof(𝑃.𝑎)
    if 𝑃.𝑎 != 𝑄.𝑎 || 𝑃.𝑏 != 𝑄.𝑏
        throw(DomainError("Points are not on the same curve"))

    # Case 0
    elseif 𝑃.𝑥 == ∞
        return 𝑄
    elseif 𝑄.𝑥 == ∞
        return 𝑃
    elseif 𝑃.𝑥 == 𝑄.𝑥 && 𝑃.𝑦 != 𝑄.𝑦
        # something more elegant should exist to return correct point type
        if T <: Point
            return Point{Infinity,S}(∞, ∞, 𝑃.𝑎, 𝑃.𝑏)
        elseif T <: S256Point
            return S256Point{Infinity}(∞, ∞, 𝑃.𝑎, 𝑃.𝑏)
        end

    # Case 1
    elseif 𝑃.𝑥 != 𝑄.𝑥
        λ = (𝑄.𝑦 - 𝑃.𝑦) ÷ (𝑄.𝑥 - 𝑃.𝑥)
        𝑥 = λ^2 - 𝑃.𝑥 - 𝑄.𝑥
    # Case 2
    else
        λ = (3 * 𝑃.𝑥^2 + 𝑃.𝑎) ÷ (2 * 𝑃.𝑦)
        𝑥 = λ^2 - 2 * 𝑃.𝑥
    end
    𝑦 = λ * (𝑃.𝑥 - 𝑥) - 𝑃.𝑦
    return T(S(𝑥), S(𝑦), 𝑃.𝑎, 𝑃.𝑏)
end

"Scalar multiplication of a Point"
function *(λ::Integer,𝑃::Point)
    𝑅 = Point(∞, ∞, 𝑃.𝑎, 𝑃.𝑏)
    while λ > 0
        𝑅 += 𝑃
        λ -= 1
    end
    return 𝑅
end
