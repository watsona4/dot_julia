module AdjacentFloats

export prev_float, next_float

import Base: nextfloat, prevfloat


function next_float(x::Float64)
    x !== -Inf && return next_float_signed(x) 
    return -realmax(Float64)
end

function prev_float(x::Float64)
    x !== Inf && return prev_float_signed(x) 
    return realmax(Float64)
end

@inline function prev_float_signed(x::Float64)
    signbit(x) ? next_awayfrom_zero(x) : next_nearerto_zero(x)
end

@inline function next_float_signed(x::Float64)
    signbit(x) ? next_nearerto_zero(x) : next_awayfrom_zero(x)
end

@inline next_nearerto_zero(x::Float64) = -fma(+1.1102230246251568e-16, x, -x) + 5.0e-324
@inline next_awayfrom_zero(x::Float64) =  fma(+1.1102230246251568e-16, x,  x) + 5.0e-324


function next_float(x::Float32)
    x !== -Inf32 && return next_float_signed(x) 
    return -realmax(Float32)
end

function prev_float(x::Float32)
    x !== Inf32 && return prev_float_signed(x) 
    return realmax(Float32)
end

@inline function prev_float_signed(x::Float32)
    signbit(x) ? next_awayfrom_zero(x) : next_nearerto_zero(x)
end

@inline function next_float_signed(x::Float32)
    signbit(x) ? next_nearerto_zero(x) : next_awayfrom_zero(x)
end

@inline next_nearerto_zero(x::Float32) = -fma(+5.960465f-8, x, -x) + 1.435f-42
@inline next_awayfrom_zero(x::Float32) =  fma(+5.960465f-8, x,  x) + 1.435f-42


function next_float(x::Float16)
    x !== -Inf16 && return next_float_signed(x) 
    return -realmax(Float16)
end

function prev_float(x::Float16)
    x !== Inf16 && return prev_float_signed(x) 
    return realmax(Float16)
end

@inline function prev_float_signed(x::Float16)
    signbit(x) ? next_awayfrom_zero(x) : next_nearerto_zero(x)
end

@inline function next_float_signed(x::Float16)
    signbit(x) ? next_nearerto_zero(x) : next_awayfrom_zero(x)
end

@inline next_nearerto_zero(x::Float16) = signbit(x) ? nextfloat(x) : prevfloat(x)
@inline next_awayfrom_zero(x::Float16) = signbit(x) ? prevfloat(x) : nextfloat(x)


# fallbacks

prev_float(x::BigFloat) = prevfloat(x)
next_float(x::BigFloat) = nextfloat(x)

prev_float(x::T) where {T<:AbstractFloat} = prevfloat(x)
next_float(x::T) where {T<:AbstractFloat} = nextfloat(x)

end # module
