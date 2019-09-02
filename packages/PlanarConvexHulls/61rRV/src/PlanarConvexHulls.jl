module PlanarConvexHulls

export
    ConvexHull,
    SConvexHull,
    DConvexHull,
    CW,
    CCW,
    vertices,
    num_vertices,
    area,
    centroid,
    is_ordered_and_strongly_convex,
    closest_point,
    jarvis_march!,
    hrep,
    hrep!

using LinearAlgebra
using StaticArrays
using StaticArrays: arithmetic_closure
using DocStringExtensions

include("order.jl")
include("util.jl")
include("exceptions.jl")
include("core_types.jl")
include("area.jl")
include("convexity_test.jl")
include("centroid.jl")
include("membership.jl")
include("closest_point.jl")
include("jarvis_march.jl")
include("hrep.jl")

end # module
