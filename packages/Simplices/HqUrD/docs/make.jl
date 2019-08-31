using Documenter, Simplices
ENV["GKSwstype"] = "100"
push!(LOAD_PATH,"../src/")

PAGES = [
    "Overview" => "index.md",
    "Properties of simplices" => "simplexproperties.md",
    "Simplex intersection" => [
        "How to calculate intersections?" => "simplexintersection.md",
        "Generate intersecting simplices" => "generatesimplices.md",
        "Examples" => "examples.md",
    ],
    "Function reference" => "funcs.md"
    ]

makedocs(
    modules = [Simplices],
    format = :html,
    sitename = "Simplices.jl",
    authors = "Kristian Agasøster Haaga",
    pages = PAGES
    # Use clean URLs, unless built as a "local" build
    #html_prettyurls = !("local" in ARGS),
    #html_canonical = "https://kahaaga.github.io/Simplices.jl/latest/"
)

deploydocs(
    repo   = "github.com/kahaaga/Simplices.jl.git",
    julia  = "1.0",
    target = "build",
    deps = nothing,
    make = nothing,
    osname = "linux"
)
