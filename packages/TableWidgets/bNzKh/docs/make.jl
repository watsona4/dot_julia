using Documenter, TableWidgets

makedocs(
    format = :html,
    sitename = "TableWidgets",
    authors = "Pietro Vertechi",
    pages = [
        "Introduction" => "index.md",
        "API reference" => "api_reference.md",
    ]
)

deploydocs(
    repo = "github.com/piever/TableWidgets.jl.git",
    target = "build",
    julia  = "1.0",
    osname = "linux",
    deps   = nothing,
    make   = nothing
)
