# This file is a part of EncodedArrays.jl, licensed under the MIT License (MIT).

import Test
Test.@testset "Package EncodedArrays" begin

include("test_encoded_array.jl")
include("test_varlen_io.jl")
include("test_varlen_diff_codec.jl")

end # testset
