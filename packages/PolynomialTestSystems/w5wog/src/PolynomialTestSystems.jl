module PolynomialTestSystems

    import MultivariatePolynomials
    const MP = MultivariatePolynomials

    import DynamicPolynomials: Polynomial, PolyVar, @polyvar, differentiate
    using LinearAlgebra

    include("testsystem.jl")
    include("systems.jl")

end
