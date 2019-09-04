using UnivariateFunctions
using Test

# Run tests

println("Test of UnivariateFunctions package.")
@time @test include("1_basic_tests.jl")
@time @test include("2_date_tests.jl")
@time @test include("3_piecewise_tests.jl")
@time @test include("4_schumaker_test.jl")
@time @test include("5_interpolation_test.jl")
@time @test include("6_test_regressions.jl")
