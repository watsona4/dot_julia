using Documenter, OnlinePackage

makedocs(;
    modules=[OnlinePackage],
    format=:html,
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/bramtayl/OnlinePackage.jl/blob/{commit}{path}#L{line}",
    sitename="OnlinePackage.jl",
    authors="Brandon Taylor",
    assets=[],
)

deploydocs(;
    repo="github.com/bramtayl/OnlinePackage.jl",
    target="build",
    deps=nothing,
    make=nothing,
)
