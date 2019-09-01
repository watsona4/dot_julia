using Documenter
using ErdosExtras

makedocs(
    modules = [ErdosExtras]
    )

deploydocs(
    deps = Deps.pip("pygments", "mkdocs", "mkdocs-material", "python-markdown-math"),
    repo   = "github.com/CarloLucibello/ErdosExtras.jl.git",
    julia  = "0.6"
    )
