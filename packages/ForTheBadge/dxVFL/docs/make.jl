using Documenter, ForTheBadge

makedocs(;
    modules=[ForTheBadge],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/asinghvi17/ForTheBadge.jl/blob/{commit}{path}#L{line}",
    sitename="ForTheBadge.jl",
    authors="Anshul Singhvi",
    assets=String[],
)

deploydocs(;
    repo="github.com/asinghvi17/ForTheBadge.jl",
)
