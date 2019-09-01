using Documenter
using DarkSky

makedocs(
    modules = [DarkSky],
    doctest = false
)

deploydocs(
    deps   = Deps.pip("pygments", "mkdocs", "mkdocs-material", "python-markdown-math"),
    repo   = "github.com/ellisvalentiner/DarkSky.jl.git",
    julia  = "0.7"
)
