using Autologistic
using LightGraphs, DataFrames, CSV, Plots
using Documenter
makedocs(
    sitename = "Autologistic.jl",
    modules = [Autologistic],
    pages = [
        "index.md",
        "Background.md",
        "Design.md",
        "BasicUsage.md",
        "Examples.md",
        "api.md"
    ]
)
deploydocs(
    repo = "github.com/kramsretlow/Autologistic.jl.git",
)