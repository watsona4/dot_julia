# MIT License
# Copyright (c) 2017: Xavier Gandibleux, Anthony Przybylski, Gauthier Soleilhac, and contributors.
mutable struct mono_problem
    pb::problem
    psize::Int
    p::Vector{Int} #combined profit vector
    p1::Vector{Int}
    p2::Vector{Int}
    w::Vector{Int}
    c::Int
    C0::Vector{Int} #Variables that have been fixed to 0 for the mono_problem only
    C1::Vector{Int} #Variables that have been fixed to 1 for the mono_problem only
    ω::Int #Minimum weight
    min_profit_λ::Int
    min_profit_1::Int
    min_profit_2::Int
    eff::Vector{Float64}
    variables::Vector{Int} #Order of variables with decreasing utiliy wrt to the combined objective
    ub_z1_i0::Vector{Int} #Upper bound on z1 for each variable i fixed to 0
    ub_z1_i1::Vector{Int} #Upper bound on z1 for each variable i fixed to 1
    ub_z2_i0::Vector{Int} #Upper bound on z2 for each variable i fixed to 0
    ub_z2_i1::Vector{Int} #Upper bound on z2 for each variable i fixed to 1
end

#Printer
Base.show(io::IO, pb::mono_problem) =
    print(io, "Mono-objective Knapsack Problem with $(size(pb))($(pb.psize)) variables :
\tω=$(pb.ω)\n\tc=$(pb.c)\n\tvars=$(pb.variables)\n\tp=$(pb.p[pb.variables])\n\tw=$(pb.w[pb.variables])")

size(pb::mono_problem)::Int = length(pb.variables)
variables(pb::mono_problem)::Vector{Int} = pb.variables

function fix!(mp::mono_problem, C0::Vector{Int}, C1::Vector{Int})
    for i in C0
        v = mp.variables[i]
        push!(mp.C0, v)
    end
    for i in C1
        v = mp.variables[i]
        push!(mp.C1, v)
        mp.min_profit_λ += mp.p[v]
        mp.min_profit_1 += mp.p1[v]
        mp.min_profit_2 += mp.p2[v]
        mp.ω += mp.w[v]
    end
    deleteat!(mp.variables, sort(vcat(C0,C1)))
end

#Constructor from a bi_problem
function mono_problem(p::problem, λ1::Int, λ2::Int, calculate_efficiency::Bool = true) 
    
    profits = λ1*p.p1 + λ2*p.p2
    eff = calculate_efficiency ? profits ./ p.w : Float64[]
    vars = variables(p)[:]
    calculate_efficiency && sort!(vars, by = x -> eff[x], rev=true)

    return mono_problem(
        p,
        size(p), #Number of variables
        profits, #Combined profit vector
        p.p1,
        p.p2,
        p.w, #Weight vector
        p.c, #Capacity
        Int[], #C0
        Int[], #C1
        p.ω, #ω
        λ1*p.min_profit_1 + λ2*p.min_profit_2,#min_profit
        p.min_profit_1,
        p.min_profit_2,
        eff, #Utility vector
        vars, #variables
        p.ub_z1_i0,
        p.ub_z1_i1,
        p.ub_z2_i0,
        p.ub_z2_i1
        )
end

function reduce!(mp::mono_problem, Δ, output::Bool)

    #Here, C0 and C1 will contain not the variables to be fixed to 0/1 but their indices in mp.variables
    #It makes their removal faster : we don't have to use findfirst(...) to find the values we have to remove from mp.variables
    lb_zλ, lb_z1, lb_z2 = Δ.lb, obj_1(Δ.xr), obj_2(Δ.xs)
    vars = variables(mp)

    ### Reduction with lb_z1
    C0,C1 = Vector{Int}(), Vector{Int}()
    for i = 1:size(mp)
        if mp.ub_z1_i0[vars[i]] <= lb_z1
            push!(C1, i)
        elseif mp.ub_z1_i1[vars[i]] <= lb_z1
            push!(C0, i)
        end
    end
    ##@assert isempty(intersect(C1,C0))
    # @show C0
    # @show C1
    fix!(mp, C0, C1)
    empty!(C0) ; empty!(C1)


    #Reduction with lb_z2
    for i = 1:size(mp)
        if mp.ub_z2_i0[vars[i]] <= lb_z2
            push!(C1, i)
        end
        if mp.ub_z2_i1[vars[i]] <= lb_z2
            push!(C0, i)
        end
    end
    ##@assert isempty(intersect(C1,C0))
    fix!(mp, C0, C1)
    empty!(C0) ; empty!(C1)

    #TODO : find the break_item and only calculate C0 for variables before the break_item and C1 for those after.

    #Reduction with lb_zλ
    for i=1:size(mp)
        #Calculate relaxation with variable i set to 0
        w = mp.ω
        ub = mp.min_profit_λ
        j = 1
        while j <= size(mp) && (i==j || w + mp.w[vars[j]] <= mp.c)
            v = vars[j]
            if j != i
                w += mp.w[v]
                ub += mp.p[v]
            end
            j += 1
        end

        if j <= size(mp) 
            v = vars[j]
            cleft = mp.c - w
            if j+1 == i || j == size(mp)
                if j+2 <= size(mp)
                    U0 = ub + floor(Int, cleft * mp.p[vars[j+2]]/mp.w[vars[j+2]])
                else
                    U0 = ub
                end
            else
                U0 = ub + floor(Int, cleft * mp.p[vars[j+1]]/mp.w[vars[j+1]])
            end
            if j-1 == i || j == 1
                if j-2 >= 1
                    U1 = ub + floor(Int, mp.p[v] - (mp.w[v] - cleft)*(mp.p[vars[j-2]]/mp.w[vars[j-2]]))
                else
                    U1 = 0
                end
            else
                U1 = ub + floor(Int, mp.p[v] - (mp.w[v] - cleft)*(mp.p[vars[j-1]]/mp.w[vars[j-1]]))    
            end
        ub = max(U0,U1)
        end
        if ub < lb_zλ
            push!(C1, i)
        end

    end

    for i=1:size(mp)
        #Calculate relaxation with variable i set to 1
        w = mp.ω + mp.w[vars[i]]
        ub = mp.min_profit_λ + mp.p[vars[i]]
        j = 1
        while j <= size(mp) && (i==j || w + mp.w[vars[j]] <= mp.c)
            v = vars[j]
            if j != i
                w += mp.w[v]
                ub += mp.p[v]
            end
            j += 1
        end

        if j <= size(mp)
            v = vars[j]
            cleft = mp.c - w
            if j+1 == i || j == size(mp)
                if j+2 <= size(mp)
                    U0 = ub + floor(Int, cleft * mp.p[vars[j+2]]/mp.w[vars[j+2]])
                else
                    U0 = ub
                end
            else
                U0 = ub + floor(Int, cleft * mp.p[vars[j+1]]/mp.w[vars[j+1]])
            end
            if j-1==i || j == 1
                if j-2 >= 1
                    U1 = ub + floor(Int, mp.p[v] - (mp.w[v] - cleft)*(mp.p[vars[j-2]]/mp.w[vars[j-2]]))
                else
                    U1 = 0
                end
            else
                U1 = ub + floor(Int, mp.p[v] - (mp.w[v] - cleft)*(mp.p[vars[j-1]]/mp.w[vars[j-1]]))    
            end
        ub = max(U0,U1)
        end
        if ub < lb_zλ
            push!(C0, i)
        end
    end

    fix!(mp, C0, C1)
    reduce_again!(mp, Δ)
    output && mp.psize != size(mp) && println("Problem reduced from $(mp.psize) to $(size(mp)) variables")

    nothing
end

function reduce_again!(mp::mono_problem, Δ)

    size0 = size(mp)

    lb_zλ = Δ.lb
    vars = variables(mp)
    C0,C1 = Vector{Int}(), Vector{Int}()
    M = 500000

    for i = 1:length(vars)
        v = vars[i]
        p_old = mp.p[v] ; mp.p[v] = 0 #fix_0!(p, v)
        ms = solve_mono(mp)
        if obj(ms) < lb_zλ
            push!(C1, i)
        end
        mp.p[v] = p_old
    end

    for i = 1:length(vars)
        v = vars[i]
        if mp.ω + mp.w[v] > mp.c 
            push!(C0, i)
            continue
        end        
        
        mp.p[v] += M ; mp.min_profit_λ -= M # fix_1!(mp, v)
        ms = solve_mono(mp)
        if obj(ms) < lb_zλ
            push!(C0, i)
        end
        mp.p[v] -= M ; mp.min_profit_λ += M #unfix_0
    end

    fix!(mp, C0, C1)

    return nothing
end