using Documenter, POMDPPolicies

makedocs(
    modules = [POMDPPolicies],
    format = :html,
    sitename = "POMDPPolicies.jl"
)

deploydocs(
    repo = "github.com/JuliaPOMDP/POMDPPolicies.jl.git",
    julia = "1.0",
    osname = "linux",
    target = "build",
    deps = nothing,
    make = nothing
)