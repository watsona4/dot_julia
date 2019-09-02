using Documenter, JuliaKara

makedocs(
    format = :html,
    sitename = "JuliaKara.jl",
    pages = [
        "index.md",
        "Submodules" => [
            "actorsworld.md"
        ]
    ]
)

deploydocs(
    repo = "github.com/sebastianpech/JuliaKara.jl.git",
    target = "build",
    julia = "0.6",
    deps = nothing,
    make = nothing,
)
