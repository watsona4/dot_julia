using Documenter, ParticleScattering

makedocs(
    sitename = "ParticleScattering.jl",
    authors = "Boaz Blankrot",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    ),
    pages = Any[
        "Home" => "index.md",
        "Tutorials" => Any[
            "tutorial1.md",
            "tutorial2.md",
            "tutorial_optim_angle.md",
            "tutorial_optim_radius.md"
        ],
        "Choosing Minimal N and P" => "minimalNP.md",
        "Incident Field Types" => "incident_fields.md",
        "Adding New Shapes" => "new_shapes.md",
        "API" => "api.md"
    ]
)

deploydocs(
    repo   = "github.com/bblankrot/ParticleScattering.jl.git",
)
