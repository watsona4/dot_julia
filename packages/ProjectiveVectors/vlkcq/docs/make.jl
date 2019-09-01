using Documenter, ProjectiveVectors
using LinearAlgebra

makedocs(
    format = Documenter.HTML(),
    sitename = "ProjectiveVectors",
    pages = [
        "Index" => "index.md"
        ],
    doctest=false,
    modules=[ProjectiveVectors],
    checkdocs=:exports
)

deploydocs(
    repo   = "github.com/JuliaHomotopyContinuation/ProjectiveVectors.jl.git"
)
