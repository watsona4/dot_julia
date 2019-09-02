# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/MortarContact2D.jl/blob/master/LICENSE

using Documenter

deploydocs(
    repo = "github.com/JuliaFEM/MortarContact2D.jl.git",
    julia = "0.7",
    target = "build",
    deps = nothing,
    make = nothing)
