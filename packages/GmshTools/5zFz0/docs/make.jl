# Workaround for JuliaLang/julia/pull/28625
if Base.HOME_PROJECT[] !== nothing
    Base.HOME_PROJECT[] = abspath(Base.HOME_PROJECT[])
end

using Documenter
using DocumenterMarkdown
using GmshTools

# include("generate.jl")

makedocs(
    doctest=false,
    modules = [GmshTools],
    format = Markdown(),
)

deploydocs(
  repo = "github.com/shipengcheng1230/GmshTools.jl.git",
  deps = Deps.pip("pymdown-extensions", "pygments", "mkdocs", "python-markdown-math", "mkdocs-material"),
  target = "site",
  make = () -> run(`mkdocs build`),
)
