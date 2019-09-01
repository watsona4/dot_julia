import SpecialFunctions
using BenchmarkTools
import FunctionZeros: besselj_zero, besselj_zero_asymptotic

## Times reported below are all measured on the same machine
## Intel(R) Core(TM) i7-4712HQ CPU @ 2.30GHz

# This is an asymptotic form with more terms than
# the series used in ../src/. It gives no
# advantage as the initial point for root finding
# since the root finding takes far more time.
#
# This could be used for large enough n without
# root finding, especially if the user specifies
# a desired precision.
## time nu=1, n=20: 125ns
function besselj_zero_asymptotic_long0(nu::Real, n::Integer)
    beta = MathConstants.pi * (n + nu / 2 - 1//4)
    delta = 8 * beta
    mu = 4 * nu^2
    t1 = 1
    t2 = 4 * (7 * mu - 31) / (3 * delta^2)
    t3 = 32 * (84 * mu^2 - 982 * mu + 3779) / (15 * delta^4)
    t4 = 64 * (6949 * mu^3 - 153855 * mu^2 + 1585743 * mu - 6277237) /
        (105 * delta^6)
    return beta - (mu - 1) / delta * (t1 + t2 + t3 + t4)
end

# Here we compute the powers more efficiently. A Horner formula might be better.
# This is about 4.5 times faster than the version above.
## time nu=1, n=20: 29ns
function besselj_zero_asymptotic_long(nu::Real, n::Integer)
    beta = MathConstants.pi * (n + nu / 2 - 1//4)
    delta = 8 * beta
    mu = 4 * nu^2
    mup2 = mu * mu
    mup3 = mup2 * mu
    deltap2 = delta * delta
    deltap3 = deltap2 * delta
    deltap4 = deltap2 * deltap2
    deltap6 = deltap3 * deltap3
    t1 = 1
    t2 = 4 * (7 * mu - 31) / (3 * deltap2)
    t3 = 32 * (84 * mup2 - 982 * mu + 3779) / (15 * deltap4)
    t4 = 64 * (6949 * mup3 - 153855 * mup2 + 1585743 * mu - 6277237) /
        (105 * deltap6)
    zero_asymp = beta - (mu - 1)  / delta * (t1 + t2 + t3 + t4)
    return zero_asymp
end

# Here, we convert prefactors in the numerator and denominator to a single rational
## time nu=1, n=20: 316ns
function besselj_zero_asymptotic_long1(nu::Real, n::Integer)
    beta = MathConstants.pi * (n + nu / 2 - 1//4)
    delta = 8 * beta
    mu = 4 * nu^2
    mup2 = mu * mu
    mup3 = mup2 * mu
    deltap2 = delta * delta
    deltap3 = deltap2 * delta
    deltap4 = deltap2 * deltap2
    deltap6 = deltap3 * deltap3
    t1 = 1
    t2 = 4//3 * (7 * mu - 31) / deltap2
    t3 = 32//15  * (84 * mup2 - 982 * mu + 3779) /  deltap4
    t4 = 64//105 * (6949 * mup3 - 153855 * mup2 + 1585743 * mu - 6277237) /
        deltap6
    return beta - (mu - 1) / delta * (t1 + t2 + t3 + t4)
end

function test_besselj_zero_asymptotic_long(nu::Real, n::Integer)
    z = besselj_zero_asymptotic_long(nu, n)
    return SpecialFunctions.besselj(nu, z)
end

function test_besselj_zero_asymptotic(nu::Real, n::Integer)
    z = besselj_zero_asymptotic(nu, n)
    return SpecialFunctions.besselj(nu, z)
end

function test_besselj_zero(nu::Real, n::Integer)
    z = besselj_zero(nu, n)
    return SpecialFunctions.besselj(nu, z)
end
