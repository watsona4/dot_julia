# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/MortarContact2D.jl/blob/master/LICENSE

using Documenter, MortarContact2D

format = length(ARGS) > 0 ? Symbol(ARGS[1]) : :html

makedocs(modules=[MortarContact2D],
         format = format,
         checkdocs = :all,
         sitename = "MortarContact2D.jl",
         pages = ["index.md"]
        )
