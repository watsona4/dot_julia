# defines the SimpleTropical module with the Tropical type

module SimpleTropical

import Base.isinf, Base.show, Base.+, Base.*, Base.inv, Base.==
import Base.isequal, Base.^, Base.convert

export Tropical, TropicalInf

struct Tropical{T<:Real} <: Number
  val::T
  inf_flag::Bool

  function Tropical{T}(xx::Real, ii::Bool=false) where T
    TT = typeof(xx)
    if isinf(xx) || ii
      return new(zero(TT),true)
    end
    return new(xx,false)
  end
end

Tropical(x::T) where T<:Real = Tropical{T}(x)
function Tropical(x::T, i::Bool) where T<:Real
  if i
    return Tropical{T}(zero(T),true)
  end
  return Tropical(x)
end

"""
`TropicalInf` is a constant that represents infinity in the tropical
semiring.
"""
const TropicalInf = Tropical{Bool}(0,true)

isinf(X::Tropical) = X.inf_flag

Base.promote_rule(::Type{Tropical{T}}, ::Type{S}) where {T<:Real, S<:Real} =
    Tropical{promote_type(T, S)}
Base.promote_rule(::Type{Tropical{T}}, ::Type{Tropical{S}}) where {T<:Real, S<:Real} =
    Tropical{promote_type(T, S)}

convert(::Type{Tropical}, x::T) where {T<:Real} = Tropical{T}(x)
convert(::Type{Tropical{T}}, x::S) where {T<:Real,S<:Tropical} =
    Tropical(convert(T, x.val), x.inf_flag)

function show(io::IO, t::Tropical)
  if isinf(t)
    print(io,"Tropical($(Char(8734)))")  # infinity character
  else
    print(io,"Tropical{$(typeof(t.val))}($(t.val))")
  end
end

function (+)(x::Tropical{T}, y::Tropical{T}) where {T}
  if isinf(x)
    if isinf(y)   # when X,Y both are infinite
      return Tropical(zero(T),true)  # create common infinite
    else
      return Tropical(y)
    end
  end

  if isinf(y)
    return Tropical(x)
  end

  return Tropical(min(x.val, y.val))
end
(+)(x::Tropical{T}, y::Tropical{S}) where {T,S} = +(promote(x, y)...)
(+)(x::Tropical{T}, y::Real) where T = +(promote(x, y)...)
(+)(x::Real, y::Tropical{T}) where T = +(promote(x, y)...)

function (*)(x::Tropical{T}, y::Tropical{T}) where {T}
  if isinf(x) || isinf(y)
    return Tropical(zero(T),true)
  end

  return Tropical(x.val + y.val)
end
(*)(x::Tropical{T}, y::Tropical{S}) where {T,S} = *(promote(x, y)...)
(*)(x::Tropical{T}, y::Real) where T = *(promote(x, y)...)
(*)(x::Real, y::Tropical{T}) where T = *(promote(x, y)...)

function inv(X::Tropical)
  @assert !isinf(X) "TropicalInf is not invertible"
  return Tropical(-X.val)
end

function (^)(X::Tropical, p::Integer)
  if isinf(X)
    @assert p>0 "Cannot raise tropical infinity to a nonpositive power."
    return X
  end

  return Tropical(X.val * p)
end


function isequal(X::Tropical, Y::Tropical)
  if !isinf(X) && !isinf(Y)
      return isequal(X.val, Y.val)
  else
      return isinf(X) && isinf(Y)
  end
end

function ==(X::Tropical, Y::Tropical)
  if !isinf(X) && !isinf(Y)
      return X.val == Y.val
  else
      return isinf(X) && isinf(Y)
  end
end

end # end of module
