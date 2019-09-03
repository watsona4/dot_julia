using Documenter, ProperOrthogonalDecomposition

makedocs(
        modules = [ProperOrthogonalDecomposition],
        format = :html,
        sitename = "ProperOrthogonalDecomposition.jl",
        strict = true,
        assets = ["assets/favicon.ico"],
        clean = true,
        checkdocs = :none,
        pages = Any[
                "Home" => "index.md",
                "Manual" => Any[
                        "man/POD.md",
                        "man/weightedPOD.md",
                        "man/convergence.md",
                ]
        ]
)

deploydocs(
    repo = "github.com/MrUrq/ProperOrthogonalDecomposition.jl.git",
    target = "build",
    julia = "1.0",
    deps = nothing,
    make = nothing
)
