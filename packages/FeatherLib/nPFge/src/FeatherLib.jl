module FeatherLib

using Arrow, FlatBuffers, CategoricalArrays, Mmap

export featherread, featherwrite

import Dates

const FEATHER_VERSION = 2
# wesm/feather/cpp/src/common.h
const FEATHER_MAGIC_BYTES = Vector{UInt8}(codeunits("FEA1"))
const MIN_FILE_LENGTH = 12


include("metadata.jl")  # flatbuffer defintions
include("loadfile.jl")
include("read.jl")
include("write.jl")


end # module
