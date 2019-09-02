# Workaround for JuliaLang/julia/pull/28625
if Base.HOME_PROJECT[] !== nothing
    Base.HOME_PROJECT[] = abspath(Base.HOME_PROJECT[])
end

using Documenter, PlanarConvexHulls

makedocs(
    modules = [PlanarConvexHulls],
    checkdocs = :exports,
    root = @__DIR__,
    sitename ="PlanarConvexHulls.jl",
    authors = "Twan Koolen and contributors.",
    pages = [
        "Home" => "index.md",
    ],
    format = Documenter.HTML(prettyurls = parse(Bool, get(ENV, "CI", "false")))
)

deploydocs(
    repo = "github.com/tkoolen/PlanarConvexHulls.jl.git"
)
