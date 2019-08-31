using Documenter, BBI

makedocs(
    # format = :html,
    format = Documenter.HTML(
        edit_branch = "develop"
    ),
    sitename = "BBI.jl",
    pages = [
        "Home" => "index.md",
    ],
    authors = "Kenta Sato, D. C. Jones, Ben J. Ward, Ciarán O'Mara, The BioJulia Organisation and other contributors.",
)
deploydocs(
    repo = "github.com/BioJulia/BBI.jl.git",
    target = "build",
    deps = nothing,
    make = nothing,
    devbranch = "develop"
)
