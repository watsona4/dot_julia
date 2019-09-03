module SRCWA

using LinearAlgebra,SpecialFunctions

include("grid.jl")
include("layers.jl")
include("matrices.jl")
include("ft2d.jl")
include("evaluation.jl")

using .layers,.matrices,.ft2d,.grid,.evaluations

export rectft,circft,ellipft,grid_n,grid_k,
prepare_source,layer_plain,layer_patterned,modes_freespace,halfspace,matrix_layer,matrix_ref,matrix_tra,concatenate,
a2p,a2e,absorption,stackamp,grid_xy_square,recipvec2real,slicehalf,recip2real,real2recip,field_expansion,ScatterMatrix,Layer,Halfspace

end
