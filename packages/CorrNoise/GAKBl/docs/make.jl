push!(LOAD_PATH, joinpath("..", "src"))

using Documenter, CorrNoise

makedocs(modules = [CorrNoise],
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    ),
    sitename = "CorrNoise.jl",
    pages = Any[
        "Manual" => "index.md",
    ])

deploydocs(
    repo = "github.com/ziotom78/CorrNoise.jl.git",
)
