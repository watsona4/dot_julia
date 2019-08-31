# Generates a tablaue of weights and points for Gauss Legendre quadrature
# on a line
using FastGaussQuadrature

const MAX_ORDER = 5
open(joinpath(@__DIR__, "..", "src", "quaddata.jl"), "w") do f
    println(f, "const QUAD_DATA = [")
    for g in 1:MAX_ORDER
        points, weights = gausslegendre(g)
        println(f, "[(", join(points, ", "), ",),")
        println(f, "(", join(weights, ", "), ",)],")
    end
    println(f, "]")
end

