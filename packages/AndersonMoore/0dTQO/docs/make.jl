using Documenter, AMA
 
makedocs(modules=[AMA],
        doctest=true)
 
deploydocs(deps   = Deps.pip("mkdocs", "python-markdown-math"),
    repo = "github.com/es335mathwiz/AMA.jl.git",
    julia  = "0.6.0",

    osname = "linux")

