primitive type Infinity <: Number 8 end

Infinity(x::Real) = x<0 ? reinterpret(Infinity, Int8(-1)) : x>0 ? reinterpret(Infinity, Int8(1)) : throw(DomainError("Value must not be 0"))

function show(io::IO, z::Infinity)
    if z == Infinity(1)
        inf = "∞"
    else
        inf = "-∞"
    end
    print(io, inf)
end

const ∞ = Infinity(1)

+(x::Infinity) = x
-(x::Infinity) = x == ∞ ? Infinity(-1) : ∞
inv(x::Infinity) = x

Finite = Union{Integer,FieldElement}

==(::Infinity,::Finite) = false
==(::Finite,::Infinity) = false

+(x::Infinity,::Integer...) = x
-(x::Infinity,::Integer...) = x
+(x::Infinity,y::Infinity) = x == y ? x : NaN
*(n::Signed,x::Infinity) = n == 0 ? 0 : n < 0 ? -x : x
^(x::Infinity,n::Integer) = x
