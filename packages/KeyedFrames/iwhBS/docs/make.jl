using Documenter, KeyedFrames

makedocs(;
    modules=[KeyedFrames],
    format=Documenter.HTML(prettyurls=(get(ENV, "CI", nothing)=="true")),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/invenia/KeyedFrames.jl/blob/{commit}{path}#L{line}",
    sitename="KeyedFrames.jl",
    authors="Invenia Technical Computing Corporation",
    assets=[
        "assets/invenia.css",
        "assets/logo.png",
    ],
)

deploydocs(;
    repo="github.com/invenia/KeyedFrames.jl",
    target="build",
)
