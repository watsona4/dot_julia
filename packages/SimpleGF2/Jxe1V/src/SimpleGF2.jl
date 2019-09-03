module SimpleGF2
using LinearAlgebra

import Base: show, +, -, *, /, xor, &, |, abs
import Base: convert, promote_rule, isless, real, rand


export GF2

struct GF2 <: Number
  val::UInt8
  function GF2(x::T) where T<:Integer
    new(x&1)
  end
end

convert(::Type{GF2}, x::T) where T<:Integer = GF2(x)
convert(::Type{T}, x::GF2) where T<:Integer = T(x.val)

+(x::GF2,y::GF2) = GF2(x.val+y.val)    # addition
-(x::GF2,y::GF2) = GF2(x.val+y.val)    # subtraction
-(x::GF2) = x                          # unary minus
*(x::GF2,y::GF2) = GF2(x.val & y.val)  # multiplication
function /(x::GF2,y::GF2)              # division
  if y.val == 0x00
    error("Division by zero in GF(2)")
  end
  return x
end

# Bitwise operators
xor(x::GF2,y::GF2) = GF2(xor(x.val,y.val))   # XOR
(&)(x::GF2,y::GF2) = GF2(x.val&y.val)   # AND
(|)(x::GF2,y::GF2) = GF2(x.val|y.val)   # OR

# isless defined giving all relations
isless(x::GF2,y::GF2) = isless(x.val,y.val)
isless(x::GF2,y::T) where T<:Real = isless(x.val,y)
isless(x::T,y::GF2) where T<:Real = isless(x,y.val)

abs(x::GF2) = x
real(x::GF2) = x.val

# random values and matrices
rand(::Type{GF2}) = GF2(rand(Int))
#rand(::Type{GF2},dims::Integer...) = map(GF2,rand(Int,dims...))
rand(::Type{GF2},dims::Integer...) = GF2.(rand(Int,dims...))

promote_rule(::Type{GF2}, ::Type{Int} ) = GF2

function show(io::IO, x::GF2)
  if x.val == 0x00
    print(io,"GF2(0)")
  else
    print(io,"GF2(1)")
  end
end

include("solving.jl")
# include("GF2inv.jl") -- now moved to "solving"

end # end of module
