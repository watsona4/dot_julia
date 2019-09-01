using Documenter, EntropicCone

makedocs(
    sitename = "EntropicCone",
    # See https://github.com/JuliaDocs/Documenter.jl/issues/868
    html_prettyurls = get(ENV, "CI", nothing) == "true",
    pages = [
        "Index" => "index.md",
        "Introduction" => "intro.md",
        "Entropic Vector" => "vector.md",
    ],
    # The following ensures that we only include the docstrings from
    # this module for functions define in Base that we overwrite.
    modules = [EntropicCone]
)

deploydocs(
    repo   = "github.com/blegat/EntropicCone.jl.git",
)
