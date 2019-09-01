using Documenter, GetGene

ENV["DOCUMENTER_DEBUG"] = "true"

makedocs(
    format = Documenter.HTML(),
    sitename = "GetGene",
    authors = "Chris German",
    clean = true,
    debug = true,
    pages = [
        "index.md"
    ]
)

deploydocs(
    repo   = "github.com/chris-german/GetGene.jl.git",
    target = "build"
)