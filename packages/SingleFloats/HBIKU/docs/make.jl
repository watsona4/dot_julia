using Documenter, SingleFloats

makedocs(
    modules = [SingleFloats],
    sitename = "SingleFloats.jl",
    authors = "Jeffrey Sarnoff",
    pages = Any[
        "Overview" => "index.md",
        "Examples" => "Examples.md",
    ]
)

deploydocs(
    repo = "github.com/JeffreySarnoff/SingleFloats.jl.git",
    target = "build"
)
