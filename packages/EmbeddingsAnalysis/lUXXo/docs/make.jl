using Pkg
Pkg.add("Documenter")
using Documenter, EmbeddingsAnalysis

# Make src directory available
push!(LOAD_PATH,"../src/")

# Make documentation
makedocs(
    modules = [EmbeddingsAnalysis],
    format = :html,
    sitename = "  ",
    authors = "Corneliu Cofaru, 0x0α Research",
    clean = true,
    debug = true,
    pages = [
        "Introduction" => "index.md",
        "API Reference" => "api.md",
    ]
)

# Deploy documentation
deploydocs(
    repo = "github.com/zgornel/EmbeddingsAnalysis.jl.git",
    target = "build",
    deps = nothing,
    make = nothing
)
