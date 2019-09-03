using Documenter, StaticMaps

makedocs(
    modules = [StaticMaps],
    sitename = "StaticMaps.jl",
    pages = Any[
        "Home" => "index.md",
        "API" => "api.md",
    ],
)

deploydocs(
    repo = "github.com/bhgomes/StaticMaps.jl.git",
    target = "build",
)