using Documenter, DualMatrixTools, LinearAlgebra

makedocs(
    sitename="DualMatrixTools Documentation",
    # options
    modules = [DualMatrixTools]
)

deploydocs(
    repo = "github.com/briochemc/DualMatrixTools.jl.git",
)