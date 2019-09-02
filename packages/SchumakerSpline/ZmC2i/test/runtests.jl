using SchumakerSpline
using Test

# Run tests


println("Test with Float64s")
@time @test include("Test_with_Floats.jl")
println("Test with Ints")
@time @test include("Test_with_Ints.jl")
println("Test with Dates")
@time @test include("Test_with_Dates.jl")
println("Test Intercepts")
@time @test include("test_intercepts.jl")
println("Test Splicing of Splines")
@time @test include("test_splice_splines.jl")
println("Test Plots")
@time @test include("test_plots.jl")
println("Test Extrapolation")
@time @test include("test_extrapolation.jl")
