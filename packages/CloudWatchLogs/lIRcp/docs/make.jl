using Documenter, CloudWatchLogs

makedocs(;
    modules=[CloudWatchLogs],
    format=Documenter.HTML(prettyurls=(get(ENV, "CI", nothing) == "true")),
    pages=[
        "Home" => "index.md",
        "API" => "pages/api.md",
        "Setup a Test Stack" => "pages/setup.md",
    ],
    repo="https://github.com/invenia/CloudWatchLogs.jl/blob/{commit}{path}#L{line}",
    sitename="CloudWatchLogs.jl",
    authors="Invenia Technical Computing Corporation",
    assets=[
        "assets/invenia.css",
        "assets/logo.png",
    ],
    strict = true,
    checkdocs = :exports,
)

deploydocs(;
    repo="github.com/invenia/CloudWatchLogs.jl",
    target="build",
)
