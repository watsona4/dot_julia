using Documenter, FeedbackNets, Flux

makedocs(
    sitename = "FeedbackNets Documentation",
    modules = [FeedbackNets],
    pages = [
        "Home" => "index.md"
        "Guide" => [
            "Getting Started" => "guide/getting_started.md",
            "Chains vs Trees" => "guide/chains_vs_trees.md",
            "Working with Networks" => "guide/working_with_networks.md"
        ]
        "Reference" => [
            "Overview" => "reference/reference.md",
            "Base Types" => "reference/basetypes.md",
            "Layer Types" => "reference/layers.md",
            "Network Types" => "reference/networks.md",
            "Preimplemented Models" => "reference/preimplemented.md"
        ]
    ]
)

deploydocs(
    repo = "github.com/cJarvers/FeedbackNets.jl.git"
)
