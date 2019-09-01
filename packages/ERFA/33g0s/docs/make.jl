using Documenter, ERFA

makedocs(format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true",
    ),
    sitename = "ERFA.jl",
    authors = "The JuliaAstro Contributors",
    pages = [
        "Home" => "index.md",
        "API" => "api.md",
    ],
    doctest = false,
)

deploydocs(repo = "github.com/JuliaAstro/ERFA.jl.git",
    target = "build",
)