using Documenter, SchumakerSpline

makedocs(
    format = Documenter.HTML(),
    sitename = "SchumakerSpline",
    modules = [SchumakerSpline],
    pages = ["index.md",
             "examples.md"]
)

deploydocs(
    repo   = "github.com/s-baumann/SchumakerSpline.jl.git",
    target = "build",
    deps   = nothing,
    make   = nothing
)
