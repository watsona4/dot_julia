module RiemannComplexNumbers

import Base.inv, Base.Complex, Base.show, Base.showcompact
import Base.+, Base.-, Base.*, Base./, Base.==, Base.hash
import Base: isinf, isnan, iszero, Complex, isequal

export RC, ComplexInf, ComplexNaN, IM

struct RC{T<:Complex} <: Number
    val::T
    nan_flag::Bool
    inf_flag::Bool
end


const ComplexNaN = RC((0+0im)/0,true,false)
const ComplexInf = RC(0+0im,false,true)
const IM = RC(im,false,false)

function RC(z::Complex)
    if isnan(z)
        return ComplexNaN
    end
    if isinf(z)
        return ComplexInf
    end
    return RC(z,false,false)
end

function Complex(a::RC)::Complex
    if isinf(a)
        return Inf + Inf*im
    end
    if isnan(a)
        return NaN
    end
    return a.val
end

RC(z::Real) = RC(z+0im)

isinf(z::RC) = z.inf_flag
isnan(z::RC) = z.nan_flag

function iszero(z::RC)
    if isnan(z) || isinf(z)
        return false
    end
    return iszero(z.val)
end

function show(io::IO, z::RC)
    if isinf(z)
        print(io,"ComplexInf")
    elseif isnan(z)
        print(io,"ComplexNaN")
    else
        sz = string(z.val)[1:end-2] * "IM"
        print(io,sz)
    end
end

function (==)(a::RC, b::RC)::Bool
    if isnan(a) || isnan(b)
        return false
    end
    if isinf(a) && isinf(b)
        return true
    end
    if isinf(a) || isinf(b)
        return false
    end
    return a.val == b.val
end

isequal(a::RC,b::Number) = isequal(promote(a,b)...)
isequal(a::Number,b::RC) = isequal(promote(a,b)...)

function isequal(a::RC, b::RC)::Bool
    # for isequal, nan's compare true
    if isnan(a) && isnan(b)
        return true
    end
    # but if only one is nan, then it's false
    if isnan(a) || isnan(b)
        return false
    end
    ## complex infinites are equal
    if isinf(a) && isinf(b)
        return true
    end
    if isinf(a) || isinf(b)
        return false
    end
    # finally, fall back on isequal for Complex
    return isequal(a.val, b.val)
end




function hash(a::RC, h::UInt=UInt(0))
    if isinf(a)
        return hash(Inf,h)
    end
    if isnan(a)
        return hash(NaN,h)
    end
    return hash(a.val,h)
end




import Base.promote_rule

promote_rule(::Type{RC{T}}, ::Type{S}) where {T,S} = RC

include("arithmetic.jl")
include("functions.jl")
end  # end of module
