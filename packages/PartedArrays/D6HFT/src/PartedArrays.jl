module PartedArrays
export
    PartedArray,
    PartedVector,
    PartedMatrix,
    create_partition,
    create_partition2

include("partitioning.jl")
include("partedarray.jl")

end # module
