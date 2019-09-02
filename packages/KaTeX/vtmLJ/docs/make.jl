using Documenter, KaTeX

makedocs(
    modules = [KaTeX],
    format = :html,
    sitename = "KaTeX.jl",
    pages = Any["index.md"]
)

deploydocs(
    repo = "github.com/piever/KaTeX.jl.git",
    target = "build",
    julia = "1.0",
    deps = nothing,
    make = nothing,
)
