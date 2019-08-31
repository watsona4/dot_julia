using Documenter, CacheServers

# make documents
makedocs(
    modules = [CacheServers],
    clean = false,
    format = :html,
    sitename = "CacheServers.jl",
    linkcheck = !("skiplinks" in ARGS),
    analytics = "UA-89508993-1",
    pages = [
        "Home" => "index.md",
        "Manual" => "man.md"
    ],
    html_prettyurls = !("local" in ARGS),
    html_canonical = "https://quantumbfs.github.io/CacheServers.jl/latest/",
)

deploydocs(
    repo = "github.com/QuantumBFS/CacheServers.jl.git",
    target = "build",
    deps = nothing,
    make = nothing,
)
