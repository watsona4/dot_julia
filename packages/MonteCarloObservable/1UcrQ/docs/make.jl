using Documenter, DocumenterMarkdown
using MonteCarloObservable

makedocs(modules = [MonteCarloObservable], doctest=false, format = :markdown)

deploydocs(
    deps   = Deps.pip("mkdocs==0.17.5", "mkdocs-material==2.9.4", "python-markdown-math", 
        "pygments", "pymdown-extensions"),
    repo   = "github.com/crstnbr/MonteCarloObservable.jl.git",
    target = "site",
    make   = () -> run(`mkdocs build`)
)