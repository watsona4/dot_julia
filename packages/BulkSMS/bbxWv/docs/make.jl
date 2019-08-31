using Documenter
using BulkSMS


makedocs(
    format = :html,
    sitename = "BulkSMS.jl",
    pages = [
        "index.md",
    ]
)

deploydocs(
    repo = "github.com/scls19fr/BulkSMS.jl.git"
)
