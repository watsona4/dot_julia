# based on http://dx.doi.org/10.1121/1.4968792, only valid for real arguments
# returns NaN at z = 0

import SpecialFunctions

# principal constants
const t0 =  0.8830472903
const c1 =  0.9846605676 # not used
const c2 =  1.7825674761
const d1 = -0.8153693250
const d2 = -1.7189527653

# derived constants
const A0 = (2 / pi) * c2
const B0 = (2 / pi) * d2
const C0 = (2 / pi) * (d2 - d1)
const A1 = (2 / pi) * (c2 + d2)
const B1 = -B0
const C1 =  C0

_H0_fast(z::T) where {T <: Real} = besselj1(z) + A0 * (1 - cos(z)) / z + B0 * (sin(z) - z * cos(z)) / z^2 + C0 * (z * t0 - sin(z * t0)) / z^2

_H1_fast(z::T) where {T <: Real} = (2 / pi) - besselj0(z) + A1 * sin(z) / z + B1 * (1 - cos(z)) / z^2 + C1 * (1 - cos(z * t0)) / z^2
