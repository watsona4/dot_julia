using Documenter, Granular

makedocs(
    modules = [Granular],
    clean = false,
    format = :html,
    sitename = "Granular.jl",
    authors = "Anders Damsgaard",
    pages = Any[ # Compat: `Any` for 0.4 compat
        "Home" => "index.md",
        "Manual" => Any[
            "man/installation.md",
            "man/package_contents.md",
            "man/methods.md",
            "man/getting_started.md",
        ],
        "Library" => Any[
            "Public API" => "lib/public.md",
            hide("Internals" => "lib/internals.md", Any[
              "lib/internals.md",
             ])
        ]
    ],
)

deploydocs(
    repo = "github.com/anders-dc/Granular.jl.git",
)
