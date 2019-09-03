using Documenter, StanVariational

makedocs(
    modules = [StanVariational],
    format = Documenter.HTML(),
    checkdocs = :exports,
    sitename = "StanVariational.jl",
    pages = Any["index.md"]
)

deploydocs(
    repo = "github.com/goedman/StanVariational.jl.git",
)
