module ShaderAbstractions

using StaticArrays, ColorTypes, FixedPointNumbers, StructArrays, Observables
import GeometryBasics, GeometryTypes, Tables

include("types.jl")
include("uniforms.jl")
include("api.jl")

end # module
