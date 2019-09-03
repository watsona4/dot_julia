#   This file is part of ReduceLinAlg.jl. It is licensed under the MIT license
#   Copyright (C) 2018 Michael Reed

using Documenter, ReduceLinAlg

makedocs(
    # options
    modules = [ReduceLinAlg],
    doctest = false,
    format = :html,
    sitename = "ReduceLinAlg.jl",
    authors = "Michael Reed",
    pages = Any[
        "User's Manual" => "index.md",
        ]
)

deploydocs(
    target = "build",
    repo   = "github.com/JuliaReducePkg/ReduceLinAlg.jl.git",
    branch = "gh-pages",
    latest = "master",
    osname = "linux",
    julia  = "0.6",
    deps = nothing,
    make = nothing,
)
