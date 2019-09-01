using Documenter
using ExtensibleScheduler


makedocs(
    format = :html,
    sitename = "ExtensibleScheduler.jl",
    pages = [
        "index.md",
        "getting_started.md",
    ]
)

deploydocs(
    repo = "github.com/scls19fr/ExtensibleScheduler.jl.git",
)
