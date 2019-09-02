using Documenter, Inpaintings

makedocs(
    sitename="Inpaintings Documentation",
    # options
    modules = [Inpaintings]
)

deploydocs(
    repo = "github.com/briochemc/Inpaintings.jl.git",
)