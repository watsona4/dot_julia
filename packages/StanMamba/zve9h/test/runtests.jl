# Top level test script for Stan.jl
using CmdStan, StanMamba, Test, Statistics

println("Running tests for StanMamba-j1.0-v0.1.0:\n")


# Run execution_tests only if cmdstan is installed and CMDSTAN_HOME is set correctly.
execution_tests = [
  "test_bernoulli.jl",
  "test_bernoulli_nochains.jl"
]

if CMDSTAN_HOME != ""
  println("CMDSTAN_HOME set. Try to run tests.")
  @testset "StanMamba.jl" begin

    for my_test in execution_tests
        println("\n\n  * $(my_test) *\n")
        include(my_test)
    end
    
    println("\n")
  end 
else
  println("\n\nCMDSTAN_HOME not set or found.")
  println("Skipping all tests that depend on CmdStan!\n")
end
