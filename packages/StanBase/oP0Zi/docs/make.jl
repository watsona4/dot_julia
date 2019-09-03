using Documenter, StanBase

makedocs(
    modules = [StanBase],
    format = Documenter.HTML(),
    checkdocs = :exports,
    sitename = "StanBase.jl",
    pages = Any["index.md"]
)

deploydocs(
    repo = "github.com/goedman/StanBase.jl.git",
)
