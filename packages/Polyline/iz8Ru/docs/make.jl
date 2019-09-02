using Documenter

makedocs(
    modules = [polyline],
    format = :html,
    sitename = "polyline.jl",
    pages = Any[
        "Contents" => "contents.md",
        "index.md",
    ],
)

deploydocs(
    repo = "github.com/NikStoyanov/polyline.jl.git",
    target = "build",
    deps   = nothing,
    make   = nothing,
)
