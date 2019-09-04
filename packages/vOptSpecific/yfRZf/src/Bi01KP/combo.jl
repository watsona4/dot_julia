# MIT License
# Copyright (c) 2017: Xavier Gandibleux, Anthony Przybylski, Gauthier Soleilhac, and contributors.
struct combo_item
    p::Clonglong
    w::Clonglong
    x::Cint
    i::Cint
end

function solve_mono(pb::mono_problem,lb=0,ub=0)

    if isempty(variables(pb))
        return mono_solution(pb, BitArray(0), 0, 0)
    end

    #If all items fit in the KP (which happens sometimes when doing variable reductions), 
    #combo throws a ReadOnlyMemoryError()
    if sum(x -> pb.w[x], variables(pb)) + pb.ω <= pb.c
        return mono_solution(pb, trues(size(pb)), sum(x -> pb.p[x], variables(pb)), sum(x -> pb.w[x], variables(pb)))
    end


    #@assert all(x -> x>=0, pb.p) "$(pb.p)"
    #@assert all(x -> x>0, pb.w)

    items = [combo_item(pb.p[j], pb.w[j], 0, i) for (i,j) in enumerate(variables(pb))]

    z = ccall((:solve,libcomboPath),
    Clonglong, 
    (Ref{combo_item}, Cint, Clonglong, Clonglong, Clonglong),
    items, size(pb), pb.c - pb.ω, lb, ub)

    # #@assert lb <= z <= ub

    vars = falses(size(pb))
    for it in items
        it.x==1 && (vars[it.i]=true)
    end

    #If combo can't find a solution better than the lower bound,
    #it returns z = lb with an empty solution...
    #in that case, we recalculate z
    if z == lb
        z = dot(pb.p, vars, pb.variables)
    end

    #@assert z == dot(pb.p, vars, pb.variables) "$z != $(dot(pb.p, vars, pb.variables)) $lb $ub"

    return mono_solution(pb, vars, z, dot(pb.w, vars, pb.variables))

end