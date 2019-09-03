using Documenter
using Pushover


makedocs(
    format = :html,
    sitename = "Pushover.jl",
    pages = [
        "index.md",
    ]
)

deploydocs(
    repo = "github.com/scls19fr/Pushover.jl.git"
)
