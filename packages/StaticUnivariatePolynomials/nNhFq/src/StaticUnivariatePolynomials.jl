module StaticUnivariatePolynomials

export
    AbstractPolynomial,
    Polynomial,
    BernsteinPolynomial

using Base: tail

include("util.jl")
include("abstract_polynomial.jl")
include("monomial_basis.jl")
include("bernstein_basis.jl")

end # module
