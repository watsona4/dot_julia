using Documenter, BeliefUpdaters


makedocs(
    modules = [BeliefUpdaters],
    format = :html,
    sitename = "BeliefUpdaters.jl"
)

deploydocs(
    repo = "github.com/JuliaPOMDP/BeliefUpdaters.jl.git",
    julia = "1.0",
    osname = "linux",
    target = "build",
    deps = nothing,
    make = nothing
)
