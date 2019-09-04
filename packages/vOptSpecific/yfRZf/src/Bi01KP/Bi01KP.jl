# MIT License
# Copyright (c) 2017: Xavier Gandibleux, Anthony Przybylski, Gauthier Soleilhac, and contributors.
module Bi01KP

using DataStructures, Compat

include("problem.jl") #Defines problems and reduce_problem!()
include("mono_problem.jl") #Defines mono_problems
include("solution.jl") #Defines solutions
include("mono_solution.jl") #Defines mono_solutions
include("combo.jl") #API to call Combo to solve mono-objective problems
include("first_phase.jl") #first_phase(pb::problem) -> XSE1m
include("vertex.jl") #Defines vertices
include("arc.jl") #Defines arcs, paths(arclists) and partitions
include("second_phase.jl")
include("graph.jl") 
# include("BoundSetReduction.jl")

const libcomboPath = joinpath(@__DIR__,"..","..","deps","libcombo.so")

function solve(pb::problem, output=true)
    reduce_problem!(pb, output)
    XSE1m = first_phase(pb)
    if length(XSE1m) == 1
        X = XSE1m
    else
        X = second_phase(XSE1m, output)
    end
    z1, z2 = map(obj_1, X), map(obj_2, X)
    w = map(weight, X)
    x = map(full_variable_vector, X)
    z1, z2, w, x
end

function parseKP(fname::AbstractString)
    if fname[end-2:end] == "KNP"
        f = open(fname)
        while !(readline(f)[1]=='n') end
        readline(f)
        x = readdlm(f)
        p1 = convert(Vector{Int},x[1:findfirst(x[:,3], "")-1 , 3])
        p2 = convert(Vector{Int},x[1:findfirst(x[:,4], "")-1 , 4])
        w = convert(Vector{Int},x[1:findfirst(x[:,2], "")-1 , 2])
        c = Int(x[findfirst(x[:,1], "W"), 2])
    elseif any(contains.(fname, ["TA","TB","TC","TD"]))
        f = open(fname)
        x = readdlm(f, skipstart=4)
        p1 = convert(Vector{Int},x[1:findfirst(x[:,3], "")-1 , 3])
        p2 = convert(Vector{Int},x[1:findfirst(x[:,4], "")-1 , 4])
        w = convert(Vector{Int},x[1:findfirst(x[:,2], "")-1 , 2])
        c = Int(x[findfirst(x[:,1], "W"), 2])
    else
        f = open(fname)
        x = convert(Array{Int},readdlm(f, skipstart=11))[:,1]
        close(f)
        n = (length(x)-1) ÷ 3
        c = x[end]
        p1 = x[1:n]
        p2 = x[n+1:2n]
        w = x[2n+1:3n]
    end
    return problem(p1,p2,w,c)
end

end