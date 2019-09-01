using Documenter, FTPServer

makedocs(;
    modules=[FTPServer],
    format=Documenter.HTML(assets = ["assets/invenia.css", "assests/logo.png"]),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/invenia/FTPServer.jl/blob/{commit}{path}#L{line}",
    sitename="FTPServer.jl",
    authors="Invenia Technical Computing Corporation",
)

deploydocs(;
    repo="github.com/invenia/FTPServer.jl",
    target="build",
    deps=nothing,
    make=nothing,
)
