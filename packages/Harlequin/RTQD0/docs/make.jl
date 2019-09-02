push!(LOAD_PATH, joinpath("..", "src"))

using Documenter, Harlequin

makedocs(;
    modules=[Harlequin],
    format=Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
    ),
    pages=[
        "Home" => "index.md",
        "Pointing generation" => "genpointings.md",
        "Map-making" => "mapmaking.md",
        "Practical examples" => "examples.md",
    ],
    repo="https://github.com/ziotom78/Harlequin.jl/blob/{commit}{path}#L{line}",
    sitename="Harlequin.jl",
    authors="Maurizio Tomasi",
)

deploydocs(;
    repo="github.com/ziotom78/Harlequin.jl",
)
