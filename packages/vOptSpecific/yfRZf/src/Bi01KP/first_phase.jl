# MIT License
# Copyright (c) 2017: Xavier Gandibleux, Anthony Przybylski, Gauthier Soleilhac, and contributors.
function solveWeightedSum(pb::problem, λ1::Int, λ2::Int, lb::Int=0)
    mono_p = mono_problem(pb, λ1, λ2, false)
    mono_s = solve_mono(mono_p,lb)
    return solution(mono_s)
end


#Calcul de X_SE1m par dichotomie
function solveRecursion(xr::solution, xs::solution, X::Vector{solution})

    λ1 = obj_2(xr) - obj_2(xs)
    λ2 = obj_1(xs) - obj_1(xr)

    lb = λ1*xr.obj_1 + λ2*xr.obj_2

    x = solveWeightedSum(xr.pb, λ1, λ2, lb)

    if λ1*x.obj_1 + λ2*x.obj_2 > lb
        push!(X, x)
        solveRecursion(xr, x, X)
        solveRecursion(x, xs, X)
    end
    nothing
end

function first_phase(pb::problem)

    xr = solveWeightedSum(pb, 0, 1)
    xs = solveWeightedSum(pb, 1, 0)
    X = [xr,xs]

    solveRecursion(xr, xs, X)

    sort!(X, by = obj, lt = isless, alg=QuickSort)

    del_inds = Int[]
    for i = 1:length(X)-1
        X[i] >= X[i+1] && push!(del_inds, i+1)
        X[i] <= X[i+1] && push!(del_inds, i)
    end
    deleteat!(X, del_inds)
    return unique(obj, X)
end