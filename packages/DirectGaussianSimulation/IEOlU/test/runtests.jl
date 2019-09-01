using GeoStatsBase
using GeoStatsDevTools
using Variography
using DirectGaussianSimulation
using Plots; gr(size=(1000,400))
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

@testset "DirectGaussianSimulation.jl" begin
  geodata = PointSetData(Dict(:z => [0.,1.,0.,1.,0.]), [0. 25. 50. 75. 100.])
  domain = RegularGrid{Float64}(100)

  @testset "Conditional simulation" begin
    problem = SimulationProblem(geodata, domain, :z, 2)
    solver = DirectGaussSim(:z => (variogram=SphericalVariogram(range=10.),))

    Random.seed!(2018)
    solution = solve(problem, solver)

    if visualtests
      @plottest plot(solution) joinpath(datadir,"CondSimSol.png") !istravis
    end
  end

  @testset "Unconditional simulation" begin
    problem = SimulationProblem(domain, :z => Float64, 2)
    solver = DirectGaussSim(:z => (variogram=SphericalVariogram(range=10.),))

    Random.seed!(2018)
    solution = solve(problem, solver)

    if visualtests
      @plottest plot(solution) joinpath(datadir,"UncondSimSol.png") !istravis
    end
  end
end
