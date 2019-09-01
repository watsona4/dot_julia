# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/FEMSparse.jl/blob/master/LICENSE

module FEMSparse

using SparseArrays

include("sparsematrixcoo.jl")
#include("sparsevectorcoo.jl")
#include("sparsevectordok.jl")
include("sparsematrixcsc.jl")

export SparseMatrixCOO, add!

end
