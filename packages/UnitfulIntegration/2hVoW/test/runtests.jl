using UnitfulIntegration
using Test

import QuadGK
using Unitful
import Unitful: m, s, DimensionError

# Test physical quantity-valued functions
@test QuadGK.quadgk(x->x*m, 0.0, 1.0, atol=0.0m)[1] ≈ 0.5m

# Test integration over an axis with units
@test QuadGK.quadgk(ustrip, 0.0m, 1.0m, atol=0.0m)[1] ≈ 0.5m

# Test integration where the unitful domain is infinite or semi-infinite
@test QuadGK.quadgk(x->exp(-x/(1.0m)), 0.0m, Inf*m, atol=0.0m)[1] ≈ 1.0m
@test QuadGK.quadgk(x->exp(x/(1.0m)), -Inf*m, 0.0m, atol=0.0m)[1] ≈ 1.0m
@test QuadGK.quadgk(x->exp(-abs(x/(1.0m))),
    -Inf*m, Inf*m, atol=0.0m)[1] ≈ 2.0m

# Test mixed case (physical quantity-valued f and unitful domain)
@test QuadGK.quadgk(t->ustrip(t)*m/s, 0.0s, 2.0s, atol=0.0m)[1] ≈ 2.0m

# Test that errors are thrown when dimensionally unsound
@test_throws DimensionError QuadGK.quadgk(ustrip, 0.0m, 1.0s)[1]
@test_throws DimensionError QuadGK.quadgk(ustrip, 0.0, 1.0m)[1]

# Test that we throw an error when atol is not specified (at present
# I believe it is only possible to check when the domain is unitful)
@test_throws ErrorException QuadGK.quadgk(ustrip, 0.0m, 1.0m)
