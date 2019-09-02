using Documenter, MonteCarloObservable

makedocs(
    # options

)

makedocs(
    modules = [MonteCarloObservable],
    format = :html,
    sitename = "MonteCarloObservable.jl",
    pages = [
        "Home" => "index.md",
        "Manual" => [
            "Getting started" => "manual/gettingstarted.md",
            "Type of the mean" => "manual/meantype.md",
            "Error estimation" => "manual/errorestimation.md",
            "Memory / disk storage" => "manual/memdisk.md"
        ],
        "Methods" => [
            # "All" => "methods/all.md",
            "General" => "methods/general.md",
            "Statistics" => "methods/statistics.md",
            "IO" => "methods/io.md",
            "Plotting" => "methods/plotting.md"
        ]
    ]
)

deploydocs(
    repo   = "github.com/crstnbr/MonteCarloObservable.jl.git",
    target = "build",
    deps   = nothing,
    make   = nothing,
    julia  = "release",
    osname = "linux"
)
