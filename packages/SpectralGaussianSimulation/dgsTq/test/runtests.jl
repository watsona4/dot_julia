using GeoStatsBase
using GeoStatsDevTools
using Variography
using SpectralGaussianSimulation
using Plots; gr(size=(950,200))
using VisualRegressionTests
using Test, Pkg, Random

# workaround GR warnings
ENV["GKSwstype"] = "100"

# environment settings
islinux = Sys.islinux()
istravis = "TRAVIS" ∈ keys(ENV)
datadir = joinpath(@__DIR__,"data")
visualtests = !istravis || (istravis && islinux)
if !istravis
  Pkg.add("Gtk")
  using Gtk
end

@testset "SpectralGaussianSimulation.jl" begin
  if visualtests
    problem = SimulationProblem(RegularGrid{Float64}(100,100), :z => Float64, 3)

    Random.seed!(2019)
    solver = SpecGaussSim(:z => (variogram=GaussianVariogram(range=10.),))
    solution = solve(problem, solver)
    @plottest plot(solution) joinpath(datadir,"isotropic.png") !istravis

    Random.seed!(2019)
    solver = SpecGaussSim(:z => (variogram=GaussianVariogram(distance=Ellipsoidal([20.,5.],[0.])),))
    solution = solve(problem, solver)
    @plottest plot(solution) joinpath(datadir,"anisotropic.png") !istravis
  end
end
