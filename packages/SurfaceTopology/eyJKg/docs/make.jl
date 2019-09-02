using SurfaceTopology
using Documenter
using Literate

Literate.markdown(joinpath(@__DIR__, "../examples/features.jl"), joinpath(@__DIR__,"src/"); credit = false, name = "index")

makedocs(sitename="SurfaceTopology.jl",pages = ["index.md"])

deploydocs(
     repo = "github.com/akels/SurfaceTopology.jl.git",
 )
