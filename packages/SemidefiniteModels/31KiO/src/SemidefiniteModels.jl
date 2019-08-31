module SemidefiniteModels

using Compat
using Compat.LinearAlgebra
using Compat.SparseArrays

import MathProgBase
const MPB = MathProgBase.SolverInterface

include("SD.jl")

include("sd_to_conic.jl")
include("conic_sdpa.jl")

end # module
