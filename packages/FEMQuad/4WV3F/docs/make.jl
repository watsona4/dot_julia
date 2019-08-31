# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/FEMQuad.jl/blob/master/LICENSE

using Documenter, FEMQuad

makedocs(modules=[FEMQuad],
         format = Documenter.HTML(),
         sitename = "FEMQuad.jl",
         pages = ["index.md", "api.md"])

include("deploy.jl")
