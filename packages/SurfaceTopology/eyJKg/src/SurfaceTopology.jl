module SurfaceTopology


using GeometryTypes

include("primitives.jl")
include("plainds.jl")
include("faceds.jl")
include("cachedds.jl")

include("edgeds.jl")

export FaceDS, CachedDS, EdgeDS
export FaceRing, VertexRing, EdgeRing
export Edges,Faces

end # module

