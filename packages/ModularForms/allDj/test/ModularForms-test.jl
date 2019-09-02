using ModularForms

include("poly_to_power_series-test.jl")
include("delta-test.jl")
include("eisenstein-test.jl")
include("generators-test.jl")
include("victormiller-test.jl")
include("hecke-test.jl")
include("prime_range-test.jl")
include("eta_quotient-test.jl")
include("dimensions-test.jl")

function test_all()
   test_poly_to_power_series()
   test_delta()
   test_eis_series()
   test_generators()
   test_vm_basis()
   test_hecke()
   test_prime_range()
   test_eta_quotient()
   test_dimensions()
end
