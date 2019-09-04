# MIT License
# Copyright (c) 2017: Xavier Gandibleux, Anthony Przybylski, Gauthier Soleilhac, and contributors.
mutable struct problem
    psize::Int #Number of variables
    p1::Vector{Int} #Objective vector 1
    p2::Vector{Int} #Objective vector 1
    w::Vector{Int} #Weights vector
    c::Int #Knapsack Capacity
    C0::Vector{Int} #Indices of variables always set to 0
    C1::Vector{Int} #Indices of variables always set to 1
    ω::Int #Weight of items always picked
    min_profit_1::Int #Guaranteed profit on first objective by picking the items in C1
    min_profit_2::Int #Guaranteed profit on second objective by picking the items in C1
    eff1::Vector{Float64} #Variables efficiency wrt objective 1
    eff2::Vector{Float64} #Variables efficiency wrt objective 2
    variables::Vector{Int} #Remaining variables of the problem after reduction
    ub_z1_i0::Vector{Int} #Upper bound on z1 for each variable i fixed to 0
    ub_z1_i1::Vector{Int} #Upper bound on z1 for each variable i fixed to 1
    ub_z2_i0::Vector{Int} #Upper bound on z2 for each variable i fixed to 0
    ub_z2_i1::Vector{Int} #Upper bound on z2 for each variable i fixed to 1
end

Base.copy(pb::problem) = problem(pb.psize, pb.p1, pb.p2, pb.w, pb.c, copy(pb.C0), copy(pb.C1),
    pb.ω, pb.min_profit_1, pb.min_profit_2, pb.eff1, pb.eff2, copy(pb.variables), pb.ub_z1_i0,
    pb.ub_z1_i1, pb.ub_z2_i0, pb.ub_z2_i1)  

#Printer
Base.show(io::IO, pb::problem) =
    print(io, "Bi-objective Knapsack Problem with $(size(pb))($(pb.psize)) variables :\n
p1=$(pb.p1)\np2=$(pb.p2)\nw=$(pb.w)\nc=$(pb.c)\nC0=$(pb.C0)\nC1=$(pb.C1)\n")

#Constructor
problem(p1, p2, w, c) = problem(length(w), p1, p2, w, c, Int[], Int[], 0, 0, 0, p1 ./ w, p2 ./ w, collect(1:length(w)), zeros(Int, length(w)), zeros(Int, length(w)), zeros(Int, length(w)), zeros(Int, length(w)))

size(pb::problem)::Int = length(pb.variables)
variables(pb::problem)::Vector{Int} = pb.variables

function reduce_problem!(pb::problem, output::Bool)

    n = size(pb)

    #Compute Pref(vi) and Dom(vi) ∀i = 1..n
    Pref = [Int[] for i = 1:size(pb)]
    Dom = [Int[] for i = 1:size(pb)]
    for i = 1:n-1, j = i+1:n
        i1, i2, j1, j2 = pb.p1[i], pb.p2[i], pb.p1[j], pb.p2[j]
        wi, wj = pb.w[i], pb.w[j]

        if ((i1 > j1 && i2 >= j2) || (i1 >= j1 && i2 > j2)) && wi <= wj
            push!(Pref[j], i)
            push!(Dom[i], j)
        end
        if ((j1 > i1 && j2 >= i2) || (j1 >= i1 && j2 > i2)) && wj <= wi
            push!(Pref[i], j)
            push!(Dom[j], i)
        end
    end

    #Compute LB and UB : bounds on the cardinality of an efficient solution
    c = pb.c

    w = sort(pb.w, rev=true)
    sum_weight = 0
    LB = 0
    while LB < n && w[LB+1] + sum_weight <= c
        LB += 1
        sum_weight += w[LB]
    end
    
    reverse!(w)
    sum_weight = 0
    UB = 0
    while UB < n && w[UB+1] + sum_weight <= c
        UB += 1
        sum_weight += w[UB]
    end

    #Compute C0 and C1 : sets of variables always set to 0 / 1 in an efficient solution
    C0 = pb.C0
    C1 = pb.C1
    
    for i = 1:n
        if length(Pref[i]) >= UB
            push!(C0, i)
        elseif n - length(Dom[i]) <= LB
            push!(C1, i)
        elseif !isempty(Pref[i]) && sum(j -> pb.w[j], Pref[i]) + pb.w[i] > c
            push!(C0, i)
        elseif sum(j -> j ∉ Dom[i] ? pb.w[j] : 0 , 1:n) <= c
            push!(C1, i)
        end
    end

    if !isempty(C1)
        pb.ω = sum(i -> pb.w[i], C1)
        pb.min_profit_1 = sum(i -> pb.p1[i], C1)
        pb.min_profit_2 = sum(i -> pb.p2[i], C1)
    end
    deleteat!(pb.variables, sort(union(C0,C1)))

    if output && pb.psize != size(pb)
        println("Global reduction from $(pb.psize) to $(size(pb)) variables")
    end
    
    calculate_upper_bounds!(pb)

    nothing
end

function calculate_upper_bounds!(pb::problem)
    vars = sort(variables(pb), by = v -> pb.eff1[v], rev=true)
    for i=1:size(pb)
        #Calculate relaxation with variable i set to 0
        w = pb.ω
        ub = pb.min_profit_1
        j = 1
        while j <= size(pb) && (i==j || w + pb.w[vars[j]] <= pb.c)
            v = vars[j]
            if j != i
                w += pb.w[v]
                ub += pb.p1[v]
            end
            j += 1
        end
        if j <= size(pb) 
            v = vars[j]
            cleft = pb.c - w
            if j+1 == i || j == size(pb)
                if j+2 <= size(pb)
                    U0 = ub + floor(Int, cleft * pb.p1[vars[j+2]]/pb.w[vars[j+2]])
                else
                    U0 = ub
                end
            else
                U0 = ub + floor(Int, cleft * pb.p1[vars[j+1]]/pb.w[vars[j+1]])
            end
            if j-1==i || j == 1
                if j-2 >= 1
                    U1 = ub + floor(Int, pb.p1[v] - (pb.w[v] - cleft)*(pb.p1[vars[j-2]]/pb.w[vars[j-2]]))
                else
                    U1 = 0
                end
            else
                U1 = ub + floor(Int, pb.p1[v] - (pb.w[v] - cleft)*(pb.p1[vars[j-1]]/pb.w[vars[j-1]]))    
            end
        ub = max(U0,U1)
        end
       
        pb.ub_z1_i0[vars[i]] = ub
    end
    for i=1:size(pb)
        #Calculate relaxation with variable i set to 1
        w = pb.ω + pb.w[vars[i]]
        ub = pb.min_profit_1 + pb.p1[vars[i]]
        j = 1
        while j <= size(pb) && (i==j || w + pb.w[vars[j]] <= pb.c)
            v = vars[j]
            if j != i
                w += pb.w[v]
                ub += pb.p1[v]
            end
            j += 1
        end
        if j <= size(pb) 
            v = vars[j]
            cleft = pb.c - w
            if j+1 == i || j == size(pb)
                if j+2 <= size(pb)
                    U0 = ub + floor(Int, cleft * pb.p1[vars[j+2]]/pb.w[vars[j+2]])
                else
                    U0 = ub
                end
            else
                U0 = ub + floor(Int, cleft * pb.p1[vars[j+1]]/pb.w[vars[j+1]])
            end
            if j-1==i || j == 1
                if j-2 >= 1
                    U1 = ub + floor(Int, pb.p1[v] - (pb.w[v] - cleft)*(pb.p1[vars[j-2]]/pb.w[vars[j-2]]))
                else
                    U1 = 0
                end
            else
                U1 = ub + floor(Int, pb.p1[v] - (pb.w[v] - cleft)*(pb.p1[vars[j-1]]/pb.w[vars[j-1]]))    
            end
            ub = max(U0,U1)
        end
        pb.ub_z1_i1[vars[i]] = ub
    end

    vars = sort(variables(pb), by = v -> pb.eff2[v], rev=true)

    for i=1:size(pb)
        #Calculate relaxation with variable i set to 0
        w = pb.ω
        ub = pb.min_profit_2
        j = 1 ; v = vars[j]
        j = 1
        while j <= size(pb) && (i==j || w + pb.w[vars[j]] <= pb.c)
            v = vars[j]
            if j != i
                w += pb.w[v]
                ub += pb.p2[v]
            end
            j += 1
        end
        if j <= size(pb) 
            v = vars[j]
            cleft = pb.c - w
            if j+1 == i || j == size(pb)
                if j+2 <= size(pb)
                    U0 = ub + floor(Int, cleft * pb.p2[vars[j+2]]/pb.w[vars[j+2]])
                else
                    U0 = ub
                end
            else
                U0 = ub + floor(Int, cleft * pb.p2[vars[j+1]]/pb.w[vars[j+1]])
            end
            if j-1==i || j == 1
                if j-2 >= 1
                    U1 = ub + floor(Int, pb.p2[v] - (pb.w[v] - cleft)*(pb.p2[vars[j-2]]/pb.w[vars[j-2]]))
                else
                    U1 = 0
                end
            else
                U1 = ub + floor(Int, pb.p2[v] - (pb.w[v] - cleft)*(pb.p2[vars[j-1]]/pb.w[vars[j-1]]))    
            end
            ub = max(U0,U1)
        end 
        pb.ub_z2_i0[vars[i]] = ub
    end
    for i=1:size(pb)
        #Calculate relaxation with variable i set to 1
        w = pb.ω + pb.w[vars[i]]
        ub = pb.min_profit_2 + pb.p2[vars[i]]
        j = 1
        while j <= size(pb) && (i==j || w + pb.w[vars[j]] <= pb.c)
            v = vars[j]
            if j != i
                w += pb.w[v]
                ub += pb.p2[v]
            end
            j += 1
        end
        if j <= size(pb) 
            v = vars[j]
            cleft = pb.c - w
            if j+1 == i || j == size(pb)
                if j+2 <= size(pb)
                    U0 = ub + floor(Int, cleft * pb.p2[vars[j+2]]/pb.w[vars[j+2]])
                else
                    U0 = ub
                end
            else
                U0 = ub + floor(Int, cleft * pb.p2[vars[j+1]]/pb.w[vars[j+1]])
            end
            if j-1==i || j == 1
                if j-2 >= 1
                    U1 = ub + floor(Int, pb.p2[v] - (pb.w[v] - cleft)*(pb.p2[vars[j-2]]/pb.w[vars[j-2]]))
                else
                    U1 = 0
                end
            else
                U1 = ub + floor(Int, pb.p2[v] - (pb.w[v] - cleft)*(pb.p2[vars[j-1]]/pb.w[vars[j-1]]))    
            end
            ub = max(U0,U1)
        end 
        pb.ub_z2_i1[vars[i]] = ub
    end
end