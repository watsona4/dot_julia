using Documenter, StanOptimize

makedocs(
    modules = [StanOptimize],
    format = Documenter.HTML(),
    checkdocs = :exports,
    sitename = "StanOptimize.jl",
    pages = Any["index.md"]
)

deploydocs(
    repo = "github.com/StanJulia/StanOptimize.jl.git",
)
