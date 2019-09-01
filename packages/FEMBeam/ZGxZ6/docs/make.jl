# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/FEMBeam.jl/blob/master/LICENSE

using Documenter, FEMBeam

makedocs(modules = [FEMBeam],
         format = :html,
         checkdocs = :all,
         sitename = "FEMBeam.jl",
         pages = ["index.md"])
