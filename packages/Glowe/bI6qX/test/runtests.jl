using Test
using Glowe

@testset "Model training" begin
    include("train.jl")
end

@testset "Model API" begin
    include("model.jl")
end
