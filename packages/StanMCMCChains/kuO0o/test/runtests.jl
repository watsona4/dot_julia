# Top level test script for Stan.jl
using StanMCMCChains, Test, Statistics

println("\nRunning tests for StanMCMCChains-j1.2-v5.1.0:\n")

execution_tests = [
  "test_mcmcchains.jl",
  "test_m10.4s.jl",
  "test_m12.6sl.jl"
]

@testset "StanMCMCChains.jl" begin

  for my_test in execution_tests
      println("\n\n  * $(my_test) *\n")
      include(my_test)
  end

end