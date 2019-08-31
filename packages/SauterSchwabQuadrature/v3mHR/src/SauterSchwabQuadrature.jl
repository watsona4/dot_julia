module SauterSchwabQuadrature

using LinearAlgebra
using CompScienceMeshes
using StaticArrays

export sauterschwab_parameterized
export SauterSchwabStrategy, CommonFace, CommonEdge, CommonVertex, PositiveDistance
export generate_integrand_uv


"""
Compute interaction integrals using the quadrature introduced in [1].

    sauterschwab_parameterized(integrand, strategy)

Here, `integrand` is the pull-back of the integrand into the barycentric
parameter domain of the two triangles that define the integration domain. Note
that here we use (for a planar triangle) the representation:

    x = x[3] + u*(x[1]-x[3]) + v*(x[2]-x[3])

with `u` ranging from 0 to 1 and `v` ranging from 0 to 1-`u`. This parameter
domain and representation is different from the one used in [1].

The second argument 'strategy' is an object whose type is one of

- `CommonFace`
- `CommonEdge`
- `CommonVertex`
- `PositiveDistance`

according to the configuration of the two triangular patches defining the
domain of integration. The constructors of these classes take a single
argument `acc` that defines the number of quadrature points along each of the
four axes of the final rectangular (ξ,η) integration domain (see [1], Ch 5).

[1] Sauter. Schwwab, 'Boundary Element Methods', Springer Berlin Heidelberg, 2011
"""
function sauterschwab_parameterized end

include("pulled_back_integrands.jl")
include("sauterschwabintegral.jl")
include("reorder_vertices.jl")
include("parametric_kernel_generator.jl")

end
