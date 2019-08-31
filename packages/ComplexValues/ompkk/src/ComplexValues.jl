module ComplexValues

export Polar,Spherical,S2coord

# Individually overloaded operators
import Base: Complex,complex,float,iszero,isapprox,isinf,isfinite,one,zero
import Base: +,-,*,/,sign,inv,angle,abs,abs2,real,imag,conj,show

# Utilities
cleanangle(θ) = π - mod2pi(π-θ)  # map angle to equivalent in (-pi,pi]
Float = typeof(1.)  # default base floating type 

# Definitions of the types
include("spherical.jl")
include("polar.jl")

AnyComplex{T<:AbstractFloat} = Union{Complex{T},Polar{T},Spherical{T}}
AnyNonnative{T<:AbstractFloat} = Union{Polar{T},Spherical{T}}
#AllValues = Union{Number,AnyNonnative}

complex(z::AnyNonnative) = z
float(z::AnyNonnative) = z

# promotion rules and conversion boilerplate
import Base: promote_rule
promote_rule(::Union{Type{Complex{S}},Type{S}},::Type{Spherical{T}}) where {S<:Real,T<:AbstractFloat} = Spherical{promote_type(S,T)}
promote_rule(::Union{Type{Complex{S}},Type{S}},::Type{Polar{T}}) where {S<:Real,T<:AbstractFloat} = Polar{promote_type(S,T)}
promote_rule(::Type{Polar{S}},::Type{Spherical{T}}) where {S<:AbstractFloat,T<:AbstractFloat} = Spherical{promote_type(S,T)}

# convert() boilerplate to invoke constructors
import Base.convert
convert(::Type{Complex{S}},z::AnyNonnative) where S<:Real = convert(Complex{S},Complex(z))
convert(::Type{Polar{S}},z::AnyNonnative) where S<:AbstractFloat = Polar{S}(z)
convert(::Type{Polar{S}},z::Number) where S<:AbstractFloat = Polar{S}(Complex(z))
convert(::Type{Spherical{S}},z::AnyNonnative) where S<:AbstractFloat = Spherical{S}(z)
convert(::Type{Spherical{S}},z::Number) where S<:AbstractFloat = Spherical{S}(Complex(z))

# Most other 1-argument and 2-argument base functions just get converted to regular complex
for f in [:cos,:sin,:tan,:sec,:csc,:cot,:acos,:asin,:atan,:asec,:acsc,:acot,:sincos,:sinpi,
	:cosh,:sinh,:tanh,:sech,:csch,:coth,:acosh,:asinh,:atanh,:asech,:acsch,:acoth,
	:exp,:exp10,:exp2,:expm1,:log,:log10,:log1p,:log2,:sqrt]
	quote
		import Base: $f
		$f(z::AnyNonnative) = $f(Complex(z))
	end |> eval
end

for f in [:log,:^]
	quote
		import Base: $f
		$f(z::AnyNonnative,w::AnyNonnative) = $f(Complex(z),Complex(w))
	end |> eval
end

include("plotrecipes.jl")

end # module
