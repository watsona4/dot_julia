# This file is a part of EncodedArrays.jl, licensed under the MIT License (MIT).

__precompile__(true)

module EncodedArrays

using ArraysOfArrays
using BitOperations
using FillArrays
using StructArrays

include("encoded_array.jl")
include("varlen_io.jl")
include("varlen_diff_codec.jl")

end # module
