using Documenter, StochasticIntegrals

makedocs(
    format = Documenter.HTML(),
    sitename = "StochasticIntegrals",
    modules = [StochasticIntegrals],
    pages = ["index.md"]
)

deploydocs(
    repo   = "github.com/s-baumann/StochasticIntegrals.jl.git",
    target = "build",
    deps   = nothing,
    make   = nothing
)
