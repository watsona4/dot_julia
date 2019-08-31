## Toy number type for custom algebras

struct Num{T, +, *}
    value::T
    Num(value, +, *) = new{typeof(value), +, *}(value)
    Num(value) = Num(value, +, *)
end

@inline Base.:+(a::Num{T, +, *}, b) where {T, +, *} = Num(a.value + b, +, *)
@inline Base.:+(a, b::Num{T, +, *}) where {T, +, *} = Num(a + b.value, +, *)
@inline Base.:+(a::Num{T, +, *}, b::Num{T, +, *}) where {T, +, *} = Num(a.value + b.value, +, *)
@inline Base.:+(a::Num{S, +, *}, b::Num{T, +, *}) where {S, T, +, *} = Num(a.value + b.value, +, *)

@inline Base.:*(a::Num{T, +, *}, b) where {T, +, *} = Num(a.value * b, +, *)
@inline Base.:*(a, b::Num{T, +, *}) where {T, +, *} = Num(a * b.value, +, *)
@inline Base.:*(a::Num{T, +, *}, b::Num{T, +, *}) where {T, +, *} = Num(a.value * b.value, +, *)

Base.promote_rule(::Type{Num{T, +, *}}, ::Type{S}) where {T, S, +, *} = Num{promote_type(T,S), +, *}
Base.promote_rule(::Type{Num{T, +, *}}, ::Type{Num{S, +, *}}) where {T, S, +, *} = Num{promote_type(T,S), +, *}

macro forward_1(fn)
    quote
        Base.$(fn)(x::Num{T, +, *}) where {T, +, *} = Num($(fn)(x.value), +, *)
    end
end

@forward_1 adjoint
@forward_1 transpose
@forward_1 zero

Base.show(io::IO, x::Num) = show(io, x.value)
