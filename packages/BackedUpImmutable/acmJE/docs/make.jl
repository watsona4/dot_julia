using Documenter, BackedUpImmutable

makedocs(
    modules = [BackedUpImmutable],
    format = :html,
    sitename = "BackedUpImmutable.jl",
    pages = Any[
        "Contents" => "contents.md",
        "index.md",
    ],
)

deploydocs(
    repo = "github.com/wherrera10/BackedUpImmutable.jl.git",
    target = "build",
    deps   = nothing,
    make   = nothing,
)
