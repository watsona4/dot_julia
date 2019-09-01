"""
`AbstractExecutor` is an abstract type for executors

Executors are structs which are responsible of running 
`Action` attached to a given `Job`
"""
abstract type AbstractExecutor end

include("debug.jl")
