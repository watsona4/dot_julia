using StaticUnivariatePolynomials
using Test
using ForwardDiff

import StaticUnivariatePolynomials: constant, derivative, integral, coefficient_gradient, exponential_integral

include("monomial_basis.jl")
include("bernstein_basis.jl")
