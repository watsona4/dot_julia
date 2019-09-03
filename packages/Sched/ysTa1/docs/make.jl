using Documenter
using Sched


makedocs(
    format = :html,
    sitename = "Sched.jl",
    pages = [
        "index.md",
    ]
)

deploydocs(
    repo = "github.com/scls19fr/Sched.jl"
)
