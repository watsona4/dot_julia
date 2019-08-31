using Secp256k1, Test

tests = ["FieldElement", "Infinity", "Point", "scheme-types", "ECDSA"]

for t ∈ tests
  include("$(t)_tests.jl")
end
