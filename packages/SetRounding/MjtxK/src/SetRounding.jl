module SetRounding
# Extracted from Julia base. License is MIT: https://julialang.org/license

# This file is a part of Julia. License is MIT: https://julialang.org/license

import Base.Rounding:
    setrounding

const Float32_64 = Union{Float32, Float64}

let fenv_consts = Vector{Cint}(undef, 9)
    ccall(:jl_get_fenv_consts, Nothing, (Ptr{Cint},), fenv_consts)
    global const JL_FE_INEXACT = fenv_consts[1]
    global const JL_FE_UNDERFLOW = fenv_consts[2]
    global const JL_FE_OVERFLOW = fenv_consts[3]
    global const JL_FE_DIVBYZERO = fenv_consts[4]
    global const JL_FE_INVALID = fenv_consts[5]

    global const JL_FE_TONEAREST = fenv_consts[6]
    global const JL_FE_UPWARD = fenv_consts[7]
    global const JL_FE_DOWNWARD = fenv_consts[8]
    global const JL_FE_TOWARDZERO = fenv_consts[9]
end


to_fenv(::RoundingMode{:Nearest}) = JL_FE_TONEAREST
to_fenv(::RoundingMode{:ToZero}) = JL_FE_TOWARDZERO
to_fenv(::RoundingMode{:Up}) = JL_FE_UPWARD
to_fenv(::RoundingMode{:Down}) = JL_FE_DOWNWARD

function from_fenv(r::Integer)
    if r == JL_FE_TONEAREST
        return RoundNearest
    elseif r == JL_FE_DOWNWARD
        return RoundDown
    elseif r == JL_FE_UPWARD
        return RoundUp
    elseif r == JL_FE_TOWARDZERO
        return RoundToZero
    else
        throw(ArgumentError("invalid rounding mode code: $r"))
    end
end

setrounding_raw(::Type{<:Float32_64}, i::Integer) = ccall(:fesetround, Int32, (Int32,), i)

@noinline setrounding(::Type{T}, r::RoundingMode) where {T<:Float32_64} = setrounding_raw(T, to_fenv(r))

end #module
