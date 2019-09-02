module Harlequin

export use_mpi

using Requires

# Defining use_mpi as a function instead of a constant allows the
# Julia compiler to completely optimize out "if" statements like
#
#     if use_mpi() && ...
#         ...
#     end
#
# A "const" would do the same, but we would not be able to redefine it
# in the "@require" statement below.

@doc raw"""
    use_mpi()

Return `true` if Harlequin is taking advantage of MPI, `false` if not.

"""
use_mpi() = false

function __init__()
    @require MPI="da04e1cc-30fd-572f-bb4f-1f8673147195" use_mpi() = true
end

include("quaternions.jl")
include("genpointings.jl")
include("dipole.jl")
include("beams.jl")
include("mapmaking.jl")

end # module
