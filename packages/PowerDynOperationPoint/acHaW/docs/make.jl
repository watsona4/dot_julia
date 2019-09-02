using Documenter
using PowerDynBase, PowerDynOperationPoint

makedocs(
    # options
    modules = [PowerDynBase, PowerDynOperationPoint],
    # html options
    format = :html,
    sitename = "PowerDynOperationPoint.jl",
    pages = ["index.md"],
    strict=true)
