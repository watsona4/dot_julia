using Documenter, MicrobiomePlots

makedocs(
    format = :html,
    sitename = "MicrobiomePlots.jl",
    pages = [
        "Home" => "index.md",
        "Recipes" => "recipes.md",
        "Contributing" => "contributing.md"
    ],
    authors = "Kevin Bonham, PhD"
)

deploydocs(
    repo = "github.com/BioJulia/MicrobiomePlots.jl.git",
    julia = "1.0",
    osname = "linux",
    target = "build",
    deps = nothing,
    make = nothing
)
