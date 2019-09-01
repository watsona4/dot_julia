using Documenter
include("../src/Dyn3d.jl")
using Dyn3d

makedocs(
    format = :html,
    sitename = "Dyn3d.jl",
    pages = [
        "Home" => "index.md",
        "Manual" => ["manual/construct_system.md",
        #             "manual/elements.md",
        #             "manual/velocities.md",
        #             "manual/timemarching.md",
        #             "manual/noflowthrough.md",
                    "manual/fluid_interaction.md"
                     ]
    ],
    assets = ["assets/custom.css"],
    strict = true
)


# if "DOCUMENTER_KEY" in keys(ENV)
deploydocs(
 repo = "github.com/ruizhi92/Dyn3d.jl.git",
 target = "build",
 branch = "gh-pages",
 deps = nothing,
 make = nothing,
 julia = "0.6"
)
# end
