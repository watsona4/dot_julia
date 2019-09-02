using Documenter
using PowerDynBase, PowerDynSolve, DiffEqBase

makedocs(
    # options
    modules = [PowerDynBase, PowerDynSolve],
    # html options
    format = :html,
    sitename = "PowerDynSolve.jl",
    pages = ["index.md"],
    strict=true)
