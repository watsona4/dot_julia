module NonPromoting

export NP
struct NP{T} <: AbstractFloat where {T <: AbstractFloat}
    val::T
    NP{T}(x::T) where {T <: AbstractFloat} = new{T}(x)
end

NP{T}(x::I) where {T <: AbstractFloat, I <: Integer} = NP{T}(T(x))
NP{T}(x::Rational{I}) where {T <: AbstractFloat, I <: Integer} = NP{T}(T(x))
NP{T}(x::Irrational{I}) where {T <: AbstractFloat, I} = NP{T}(T(x))
NP(x::T) where {T <: AbstractFloat} = NP{T}(x)

function Base.convert(::Type{T}, x::NP{T})::T where {T <: AbstractFloat}
    x.val
end

function Base.show(io::IO, x::NP{T}) where {T}
    show(io, x.val)
end

# Prevent promotion
Base.promote_rule(::Type{NP{T}}, ::Type{NP{T}}) where {T} = NP{T}
Base.promote_rule(::Type{NP{T}}, ::Type{NP{U}}) where {T, U} = error
Base.promote_rule(::Type{NP{T}}, ::Type) where {T} = error
Base.promote_rule(::Type, ::Type{NP{T}}) where {T} = error

# Nullary functions (which take a type as argument)
for fun in [:one, :zero]
    @eval begin
        function Base.$fun(::Type{NP{T}})::NP{T} where {T <: AbstractFloat}
            NP{T}($fun(T))
        end
    end
end

# Unary functions
for fun in [:(-),
            :abs, :acos, :acosh, :asin, :asinh, :atan, :atanh, :cbrt,
            :cos, :cosh, :exp, :exp10, :exp2,
            :inv, :log, :log10, :log2,
            :sign,:sin, :sinh, :sqrt, :tan, :tanh]
    @eval begin
        function Base.$fun(x::NP{T})::NP{T} where {T <: AbstractFloat}
            NP{T}($fun(x.val))
        end
    end
end

# Unary functions that return another type
for fun in [:isfinite, :isinf, :isnan, :issubnormal, :signbit]
    @eval begin
        function Base.$fun(x::NP{T}) where {T <: AbstractFloat}
            $fun(x.val)
        end
    end
end

# Binary functions
for fun in [:(-), :(/), :(\), :(^),
            :atan, :copysign, :hypot, :modf, :rem]
    @eval begin
        function Base.$fun(x::NP{T}, y::NP{T})::NP{T} where {T <: AbstractFloat}
            NP{T}($fun(x.val, y.val))
        end
    end
end

# Binary functions that return another type
for fun in [:(==), :(<)]
    @eval begin
        function Base.$fun(x::NP{T}, y::NP{T}) where {T <: AbstractFloat}
            $fun(x.val, y.val)
        end
    end
end

# n-ary functions
for fun in [:(+), :(*), :max, :min]
    @eval begin
        function Base.$fun(x::NP{T}, ys::NP{T}...)::NP{T} where
                {T <: AbstractFloat}
            NP{T}($fun(x.val, map(y -> y.val, ys)...))
        end
    end
end

# Functions that take additional arguments
# function Base.norm(x::NP{T}, p::Real=2)::NP{T} where {T <: AbstractFloat}
#     NP{T}(norm(x.val, p))
# end

end
