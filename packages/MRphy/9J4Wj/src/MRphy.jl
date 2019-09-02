"""
    MRphy

# General Comments
`nM`, number of spins, as magnetic spin vectors are often denoted as 𝑀.
`nT`, number of steps/time-points.
"""
module MRphy

using LinearAlgebra

using Unitful, UnitfulMR
using Unitful: 𝐋, 𝐌, 𝐈, 𝐓, NoUnits

# Magnetic field strength, Frequency, Gyro ratio in SI unit dimensions
𝐁, 𝐅 = 𝐌*𝐈^-1*𝐓^-2, 𝐓^-1
𝐊, 𝚪 = 𝐋^-1, 𝐅/𝐁

# Custom types
struct NoUnitChk end # not using, saved for future

export TypeND
"""
    TypeND(T,Ns) = Union{AbstractArray{<:T,Ns[1]}, AbstractArray{<:T,Ns[2]},...}
Sugar for creating `Union`{`<:T` typed array of different dimensions}.

# Usage
*INPUTS*:
- `T::Type` (1,), the underlying type of the union.
- `Ns::Array{Int64,1}` (# diff dims,), an array of wanted dimensions.
"""
TypeND(T::Type, Ns::Array{Int64,1}) =
  Union{(map(x->x==0 ? T : AbstractArray{D, x} where {D<:T}, Ns))...}

#=
macro TypeND(T, Ns)
  return :(Union{(map(x->x==0 ? $T : AbstractArray{D,x} where{D<:$T}, $Ns))...})
end
=#

"""
    TypeND(T, ::Colon) = AbstractArray{<:T}
Sugar for creating `<:T` typed array of arbitrary dimensions.
"""
TypeND(T::Type, ::Colon) = AbstractArray{<:T}

## Unitful types
export B0D, Γ0D, L0D, K0D, T0D, F0D, GR0D, RF0D
B0D,  Γ0D  = Quantity{<:Real, 𝐁},   Quantity{<:Real, 𝚪}
L0D,  K0D  = Quantity{<:Real, 𝐋},   Quantity{<:Real, 𝐊}
T0D,  F0D  = Quantity{<:Real, 𝐓},   Quantity{<:Real, 𝐅}
GR0D, RF0D = Quantity{<:Real, 𝐁/𝐋}, Quantity{<:Union{Real, Complex}, 𝐁}

# const
export γ¹H
"""
    γ¹H
Gyromagnetic ratio of water.
"""
const γ¹H = 4257.6u"Hz/Gauss"

# Misc

# Other files
# Common structs functions must be defined before this line, so they can be
# called by the sub-scripts.

include("utils.jl")
include("blochSim.jl")
include("mObjects.jl")

end # module

