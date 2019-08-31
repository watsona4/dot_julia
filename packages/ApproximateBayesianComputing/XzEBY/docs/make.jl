using Documenter, ApproximateBayesianComputing

makedocs(
    format = :html,
    sitename = "ApproximateBayesianComputing.jl",
#    modules = [ApproximateBayesianComputing],
#    doctest = true, 
#    clean = false,
    pages = [
        "index.md", "page1.md",
    ],
    html_prettyurls = !("local" in ARGS)

)


deploydocs(
    repo   = "github.com/eford/ApproximateBayesianComputing.jl.git",
    julia  = "0.6", 
    target = "build",
    deps   = nothing,
    make   = nothing
)

