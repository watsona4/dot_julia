using Documenter, REDCap
using Literate

makedocs()

deploydocs(
	deps = Deps.pip("mkdocs==0.17.5", "mkdocs-material==2.9.4"),
    repo = "github.com/bcbi/REDCap.jl.git",
    julia = "1.0",
    osname = "linux"
)