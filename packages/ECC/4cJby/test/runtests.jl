using ECC, Test

tests = ["helper", "primefield", "infinity", "point", "ecc"]

for t ∈ tests
  include("$(t)_tests.jl")
end
