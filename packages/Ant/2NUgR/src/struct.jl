#!/usr/bin/env julia
#=
Common structures
del2z <delta.z@aliyun.com>
=#
import Base

abstract type Model end

# Euler's formula for complex number
mutable struct Polar <: Number
    r::Real
    # -180 ~ 180
    θ::Integer
    Polar(r::Real, θ::Integer) = new(r, θ % 181)
end

function Polar(z::Complex)
    @assert(!isnan(z) && !isinf(z), "Unbounded complex number.")
    Polar(abs(z), round(Int, angle(z) / π * 180))
end

Base.complex(z::Polar) = complex(z.r * cos(z.θ / 180 * π), z.r * sin(z.θ / 180 * π))
Base.show(io::IO, z::Polar) = print(io, z.r, " * exp(", z.θ, "im)")

