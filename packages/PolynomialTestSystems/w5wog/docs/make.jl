using Documenter, PolynomialTestSystems

makedocs(
    sitename = "PolynomialTestSystems.jl",
    pages = [
        "PolynomialTestSystems" => "index.md",
    ]
)

deploydocs(
    repo   = "github.com/JuliaHomotopyContinuation/PolynomialTestSystems.jl.git",
)
