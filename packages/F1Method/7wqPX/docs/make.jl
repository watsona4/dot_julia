using Documenter, F1Method
using LinearAlgebra, DiffEqBase, ForwardDiff

makedocs(
    sitename="F1Method Documentation",
    # options
    modules = [F1Method]
)

deploydocs(
    repo = "github.com/briochemc/F1Method.jl.git",
)