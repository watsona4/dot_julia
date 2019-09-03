
# based on https://dlmf.nist.gov/11.13.iii, works for real and complex arguments
# fails at z=0 because Struve K and Bessel Y diverge there

using SpecialFunctions
using QuadGK

integrate(f, a, b) = QuadGK.quadgk(f, a, b)[1]

# only valid for real(z) > 0, https://dlmf.nist.gov/11.5.E2
_K0_integral(z::Real) = (2 / pi) * integrate(t -> exp(-z * sinh(t)), 0, Inf)
_K_integral(ν, z::Real) = 2(0.5z)^ν / (sqrt(pi) * gamma(ν + 0.5)) *
    integrate(t -> exp(-z * t) * (1 + t^2)^(ν - 0.5), 0, Inf)
_H0_integral(z::Real) = _K0_integral(z) + bessely0(z)
_H_integral(ν, z::Real) = _K_integral(ν, z) + bessely(ν, z)

# only valid for real(ν) > -0.5, https://dlmf.nist.gov/11.5.E1
_H0_integral(z::Complex{T}) where {T <: Real} = (2 / pi) *
    integrate(ϑ -> sin(z * cos(ϑ)), 0, 0.5pi)
_H_integral(ν, z::Complex{T}) where {T <: Real} = 2(0.5z)^ν /
    (sqrt(pi) * gamma(ν + 0.5)) *
    integrate(t -> (1 - t^2)^(ν - 0.5) * sin(z * t), 0, 1)
_K0_integral(z::Complex{T}) where {T <: Real} = _H0_integral(z) - bessely0(z)
_K_integral(ν, z::Complex{T}) where {T <: Real} = _H_integral(ν, z) - bessely(ν, z)

# only valid for real(ν) > -0.5, https://dlmf.nist.gov/11.5.E4
_M0_integral(z) = -(2 / pi) * integrate(ϑ -> exp(-z * cos(ϑ)), 0, 0.5pi)
_M_integral(ν, z) = -2(0.5z)^ν / (sqrt(pi) * gamma(ν + 0.5)) *
    integrate(t -> exp(-z * t) * (1 - t^2)^(ν - 0.5), 0, 1)

_L0_integral(z)   = besseli(0, z) + _M0_integral(z)
_L_integral(ν, z) = besseli(ν, z) + _M_integral(ν, z)
