__precompile__()

module Secp256k1

using BitConverter
import Base: +, -, *, ^, /, ==, inv, sqrt, show, div
export ∞, Signature, KeyPair, ECDSA

include("lib/errors.jl")
include("lib/FieldElement.jl")
include("lib/Infinity.jl")
include("lib/Point.jl")
include("lib/scheme-types.jl")
include("lib/ECDSA.jl")

end # module
