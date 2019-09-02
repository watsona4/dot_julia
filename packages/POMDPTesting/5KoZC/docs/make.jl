using Documenter
using POMDPTesting

makedocs(
    format =:html,
    sitename = "POMDPTesting.jl"
)

deploydocs(
    repo = "github.com/JuliaPOMDP/POMDPTesting.jl.git",
    julia = "1.0",
    target = "build",
    deps = nothing,
    make = nothing
)
