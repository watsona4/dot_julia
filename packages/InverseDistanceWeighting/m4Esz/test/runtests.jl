using GeoStatsBase
using GeoStatsDevTools
using InverseDistanceWeighting
using Plots; gr(size=(1000,400))
using VisualRegressionTests
using Test, Pkg

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

@testset "Basic problem" begin
  geodata = PointSetData(Dict(:variable => [1.,0.,1.]), [25. 50. 75.;  25. 75. 50.])
  domain  = RegularGrid{Float64}(100,100)
  problem = EstimationProblem(geodata, domain, :variable)

  solver = InvDistWeight(:variable => (neighbors=3,))

  solution = solve(problem, solver)

  if visualtests
    @plottest contourf(solution) joinpath(datadir,"solution.png") !istravis
  end
end
