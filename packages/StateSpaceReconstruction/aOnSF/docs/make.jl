using Documenter, StateSpaceReconstruction
push!(LOAD_PATH,"../src/")
ENV["GKSwstype"] = "100"

PAGES = [
    "Overview" => "index.md",
    "Embedding" => "embedding.md",
    "Rectangular partitions" => [
        "Types of partitions" => "partition/binningtypes.md",
        "Finding axis minima and step sizes" =>  "partition/minima_stepsizes.md",
        "Coordinate representation" => "partition/coordinate_representation.md",
        "Finding axis minima and step sizes" => "partition/minima_stepsizes.md",
        "Marginal visitation frequences" =>  "partition/marginal_visitation_frequency.md"
    ],
    "Simplex partitions" => [
        "Overview" => "simplexpartition/simplex.md"
    ]
]

makedocs(
    modules = [StateSpaceReconstruction],
    format = :markdown,
    sitename = "StateSpaceReconstruction.jl",
    authors = "Kristian Agasøster Haaga",
    pages = PAGES,
    clean = true
    # Use clean URLs, unless built as a "local" build
    #html_prettyurls = !("local" in ARGS),
    #html_canonical = "https://kahaaga.github.io/StateSpaceReconstruction.jl/latest/"
)

# deploydocs(;
#     Deps.pip("pygments", "mkdocs", "python-markdown-math"),
#     repo   = "github.com/kahaaga/StateSpaceReconstruction.jl.git",
#     julia  = "0.6",
#     target = "build",
#     deps = nothing,
#     make = nothing,
#     osname = "linux"
# )
