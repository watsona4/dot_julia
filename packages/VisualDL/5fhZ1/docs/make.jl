using Documenter, VisualDL

makedocs(modules=[VisualDL],
    doctest=false,
    format=:html,
    sitename="VisualDL.jl",
    pages=["Home" => "index.md"])

deploydocs(repo="github.com/findmyway/VisualDL.jl.git",
    target="build",
    julia="nightly",
    deps=nothing,
    make=nothing)