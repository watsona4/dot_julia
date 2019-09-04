module TextSearch
    import Base: broadcastable
    import StatsBase: fit, predict
    include("textconfig.jl")
    include("bow.jl")
    include("svec.jl")
    include("io.jl")
    include("basicmodels.jl")
    include("distmodel.jl")
    include("entmodel.jl")
    include("invindex.jl")
    include("rocchio.jl")
    include("neardup.jl")
end
