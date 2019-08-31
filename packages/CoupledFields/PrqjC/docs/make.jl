using Documenter, CoupledFields

makedocs(
    modules = [CoupledFields]
)

deploydocs(
    deps   = Deps.pip("mkdocs", "python-markdown-math"),
    repo   = "github.com/Mattriks/CoupledFields.jl.git",
    julia  = "release"
)
