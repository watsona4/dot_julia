using Test
using Hyperspecialize
push!(LOAD_PATH, ".")

@testset "Simple Concretization Pregame" begin
  # Concretization is rather persistent
  @test (@concretize Pregame String) == Set{Type}([String])
end

include("simple_concretization.jl")
include("module_concretization.jl")
include("simple_replicable.jl")
include("module_replicable.jl")
