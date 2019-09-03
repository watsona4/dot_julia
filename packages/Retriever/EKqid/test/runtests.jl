#!/usr/bin/env julia
using Pkg
push!(LOAD_PATH,"../src/Retriever.jl")
include("../src/Retriever.jl")

Pkg.add("SQLite")
Pkg.add("MySQL")

using Test

# Run tests

@time include("test_retriever.jl")

