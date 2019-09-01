module FunctionZeros
import SpecialFunctions
import Roots

export besselj_zero

# Asymptotic formula for zeros of Bessel J function of order nu
"""
    besselj_zero_asymptotic(nu, n)

Asymptotic formula for the `n`th zero fo the the Bessel J function of order `nu`.
"""
besselj_zero_asymptotic(nu, n) = pi * (n - 1 + nu / 2 + 3//4)

# Use the asymptotic values as starting values.
# These find the correct zeros even for n = 1,2,...
# Order 0 is 6 times slower and 50-100 times less accurate
# than higher orders, with other parameters constant.
"""
    besselj_zero(nu, n)

`n`th zero of the Bessel J function of order `nu`,
for `n` = `1,2,...`.
"""
besselj_zero(nu, n) = Roots.fzero((x) -> SpecialFunctions.besselj(nu, x),
                                 besselj_zero_asymptotic(nu, n); order=1)

end # module FunctionZeros
