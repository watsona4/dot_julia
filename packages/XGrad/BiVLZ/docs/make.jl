using Documenter, XGrad

makedocs(
    format = :html,
    sitename = "XGrad.jl",
    pages = [
        "Main" => "index.md",
        "Tutorial" => "tutorial.md",
        "Code Discovery" => "codediscovery.md"
    ]
)

deploydocs(
    repo   = "github.com/dfdx/XGrad.jl.git",
    target = "build",
    julia = "0.6",
    deps   = nothing,
    make   = nothing
)
