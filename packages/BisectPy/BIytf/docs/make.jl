using Documenter, BisectPy

makedocs(;
    modules=[BisectPy],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
        "Manual" => [
            "Bisect.md"
            "Insort.md"
        ]
    ],
    repo="https://github.com/singularitti/BisectPy.jl/blob/{commit}{path}#L{line}",
    sitename="BisectPy.jl",
    authors="Qi Zhang <singularitti@outlook.com>",
    assets=String[],
)

deploydocs(;
    repo="github.com/singularitti/BisectPy.jl",
)
