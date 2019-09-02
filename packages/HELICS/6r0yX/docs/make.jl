push!(LOAD_PATH, joinpath(@__DIR__, "../src/"))
using Documenter, HELICS, DocumenterMarkdown

cp(joinpath(@__DIR__, "../README.md"), joinpath(@__DIR__, "./src/index.md"), force=true, follow_symlinks=true)

makedocs(
         sitename="HELICS Julia documentation",
         format = Markdown()
        )

deploydocs(
    repo = "github.com/GMLC-TDC/HELICS.jl.git",
    deps = Deps.pip(
                   "mkdocs==0.17.5",
                   "mkdocs-material==2.9.4",
                   "python-markdown-math",
                   "pygments",
                   "pymdown-extensions",
                   ),
    make = () -> run(`mkdocs build`),
    target = "site",
)
