using Documenter

push!(LOAD_PATH, "../src/")
using ResizableArrays

DEPLOYDOCS = (get(ENV, "CI", nothing) == "true")

makedocs(
    sitename = "ResizableArrays.jl Package",
    format = Documenter.HTML(
        prettyurls = DEPLOYDOCS,
    ),
    authors = "Éric Thiébaut and contributors",
    pages = ["index.md", "install.md", "usage.md", "library.md"]
)

if DEPLOYDOCS
    deploydocs(
        repo = "github.com/emmt/ResizableArrays.jl.git",
    )
end
