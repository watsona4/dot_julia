using Documenter, AltDistributions

makedocs(
    modules = [AltDistributions],
    format = :html,
    checkdocs = :exports,
    sitename = "AltDistributions.jl",
    pages = Any["index.md"],
)

deploydocs(
    repo = "github.com/tpapp/AltDistributions.jl.git",
)
