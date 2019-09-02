module IntArrays

using Mmap

export
    IntArray,
    IntVector,
    IntMatrix,
    radixsort,
    radixsort!

include("buffer.jl")
include("array.jl")
include("vector.jl")
include("matrix.jl")

end # module
