using Documenter, particleMDI

makedocs(modules=particleMDI,
        doctest=true)

deploydocs(deps = Deps.pip("mkdocs", "python-markdown-math"),
    repo = "github.com/nathancunn/particleMDI.jl.git",
    julia  = "0.4.5",
    osname = "linux")
