# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/MortarContact2DAD.jl/blob/master/LICENSE

using Documenter, MortarContact2DAD

format = length(ARGS) > 0 ? Symbol(ARGS[1]) : :html

makedocs(modules=[MortarContact2DAD],
         format = format,
         checkdocs = :all,
         sitename = "MortarContact2DAD.jl",
         pages = ["index.md"]
        )
