using Documenter, MixedSubdivisions

makedocs(
    sitename = "MixedSubdivisions.jl",
    pages = [
        "MixedSubdivisions" => "index.md",
    ]
)

deploydocs(
    repo   = "github.com/saschatimme/MixedSubdivisions.jl.git",
)
