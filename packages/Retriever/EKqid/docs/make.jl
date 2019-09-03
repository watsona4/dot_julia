push!(LOAD_PATH,"../src/Retriever.jl")
include("../src/Retriever.jl")

Pkg.add("Documenter")
using Documenter, DocumenterTools

makedocs(
    modules = [Retriever],
    clean = false,
    format = Documenter.HTML(
        # Use clean URLs, unless built as a "local" build
        # Or set prettyurls = false
        prettyurls = !("local" in ARGS)),
    build = "build",
    sitename = "Retriever.jl",
    authors = "Ethan White",
    linkcheck = !("skiplinks" in ARGS),
    pages = [
        "Home" => "intro.md",
        "Installation Guide" => "tutorial.md",
        "Developer's Guide" => "developer.md",
        "Source" => "index.md",
        "Command Documentation" => "lib/public.md",
        "Code of Conduct" => "CODE_OF_CONDUCT.md"
    ]
)

deploydocs(
    repo = "github.com/weecology/Retriever.jl.git",
    target = "build",
    deps = nothing,
    julia = "",
    make = nothing
)
