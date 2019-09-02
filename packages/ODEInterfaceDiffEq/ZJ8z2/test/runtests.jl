using ODEInterfaceDiffEq, DiffEqProblemLibrary, DiffEqBase
using Test

@time @testset "Algorithms" begin include("algorithm_tests.jl") end
@time @testset "Saving" begin include("saving_tests.jl") end
@time @testset "Mass Matrix" begin include("mass_matrix_tests.jl") end
@time @testset "Jacobian Tests" begin include("jac_tests.jl") end
@time @testset "Callback Tests" begin include("callbacks.jl") end
