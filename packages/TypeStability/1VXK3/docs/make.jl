using Documenter
import TypeStability

if length(ARGS) > 0
    tag = ARGS[1]
else
    tag = nothing
end

makedocs(modules = [TypeStability])

deploydocs(deps = Deps.pip("mkdocs", "python-markdown-math"),
           repo = "github.com/Collegeville/TypeStability.jl",
           julia  = "0.6.4") #Currently uses the old package manager
