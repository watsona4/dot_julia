using Documenter, HyperDualMatrixTools, LinearAlgebra

makedocs(
    sitename="HyperDualMatrixTools Documentation",
    # options
    modules = [HyperDualMatrixTools]
)

deploydocs(
    repo = "github.com/briochemc/HyperDualMatrixTools.jl.git",
)