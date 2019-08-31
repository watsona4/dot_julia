using Documenter, CircularList

makedocs(;
    modules=[CircularList],
    format=:html,
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/tk3369/CircularList.jl/blob/{commit}{path}#L{line}",
    sitename="CircularList.jl",
    authors="Tom Kwong",
    assets=[],
)

deploydocs(;
    repo="github.com/tk3369/CircularList.jl",
    target="build",
    julia="1.0",
    deps=nothing,
    make=nothing,
)
