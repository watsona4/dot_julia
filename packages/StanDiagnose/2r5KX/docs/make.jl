using Documenter, StanDiagnose

makedocs(
    modules = [StanDiagnose],
    format = Documenter.HTML(),
    checkdocs = :exports,
    sitename = "StanDiagnose.jl",
    pages = Any["index.md"]
)

deploydocs(
    repo = "github.com/goedman/StanDiagnose.jl.git",
)
