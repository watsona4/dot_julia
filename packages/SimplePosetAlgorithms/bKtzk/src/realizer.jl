export realizer, dimension, realize_poset

using JuMP

_distinct(a,b,c) = (a!=b) && (a!=c) && (b!=c)


"""
`realizer(P::SimplePoset,d::Int)` creates a realizer of `P` using `d` linear
extensions or throws an error if none exists. The output is an `n`-by-`d` matrix
whose columns give the linear extensions. The first element in each column is the
bottom element of that linear extension.
"""
function realizer(P::SimplePoset{T}, d::Int) where T
    # MOD = Model(solver=SimpleGraphAlgorithms._SOLVER())
    MOD = Model(with_optimizer(SimpleGraphAlgorithms._SOLVER.Optimizer;
        SimpleGraphAlgorithms._OPTS...))

    VV = elements(P)
    n = length(VV)
    # x[u,v,t] == 1 means u<v in L_t

    @variable(MOD, x[u=VV, v=VV, t=1:d] , Bin)

    # for all i, x[i,i,t] is zero
    for u in VV
        for t in 1:d
            @constraint(MOD,x[u,u,t] == 0)
        end
    end

    # exactly one of x[u,v,t] or x[v,u,t] is 1
    for i=1:n-1
        for j=i+1:n
            u = VV[i]
            v = VV[j]
            for t=1:d
                @constraint(MOD,x[u,v,t]+x[v,u,t] == 1)
            end
        end
    end

    # if u<v x[u,v,t] == 1
    for u in VV
        for v in VV
            if has(P,u,v)
                for t in 1:d
                    @constraint(MOD, x[u,v,t] == 1)
                end
            end
        end
    end

    # if u and v are incomparable, sum(X[u,v,t]) > 0
    for i=1:n-1
        for j=i+1:n
            u = VV[i]
            v = VV[j]
            if !has(P,u,v) && !has(P,v,u)
                @constraint(MOD, sum(x[u,v,t] for t in 1:d) >= 1)
                @constraint(MOD, sum(x[v,u,t] for t in 1:d) >= 1)
            end
        end
    end

    # ensure L_t is transitive (so linear)
    for t=1:d
        for u in VV
            for v in VV
                for w in VV
                    if _distinct(u,v,w)
                        @constraint(MOD, x[u,w,t] >= x[u,v,t]+x[v,w,t]-1)
                    end
                end
            end
        end
    end

    optimize!(MOD)
    status = Int(termination_status(MOD))

    if status != 1
        error("This poset has dimension greater than $d; no realizer found.")
    end

    X = value.(x)

    PP = [ SimplePoset{T}() for t =1:d]
    for t=1:d
        for u in VV
            for v in VV
                if X[u,v,t] > 0.5
                    add!(PP[t],u,v)
                end
            end
        end
    end

    LL = [ linear_extension(PP[t]) for t=1:d ]

    result = Array{T,2}(undef,n,d)
    for t=1:d
        for i=1:n
            result[i,t] = LL[t][i]
        end
    end

    return result
end


"""
`realize_poset(R::Array{T,2})` creates a poset from a realizer.
The columns of `R` are the linear extensions of some poset; this
function returns that poset.
"""
function realize_poset(R::Array{T,2})::SimplePoset{T} where T
    n,d = size(R)
    P = make_linear_order(R[:,1])
    for j=2:d
        L = make_linear_order(R[:,j])
        P = intersect(L,P)
    end
    return P
end


function make_linear_order(lst::Array{T,1})::SimplePoset{T} where T
    P = SimplePoset{T}()
    n = length(lst)
    for i=1:n-1
        add!(P,lst[i],lst[i+1])
    end
    return P
end

"""
`dimension(P::SimplePoset, verbose=false)` returns the order-theoretic
dimension of the poset `P`. Set `verbose` to `true` to see more information
as the work is done.
"""
function dimension(P::SimplePoset, verb::Bool = false)::Int
    n = card(P)
    if n==0
        return 0
    end

    if length(incomparables(P))==0  # it's a chain
        return 1
    end

    lb = 2

    ub1 = Int(floor(n/2))
    ub2 = width(P)
    ub = max(ub1,ub2)

    return dimension_work(P, lb, ub, verb)
end

function dimension_work(P::SimplePoset, lb::Int, ub::Int, verb::Bool)::Int
    if verb
        print("$lb <= dim(P) <= $ub\t")
    end

    if lb == ub
        if verb
            println("and we're done")
        end
        return lb
    end

    mid = Int(floor((ub+lb)/2))

    if verb
        print("looking for a $mid realizer\t")
    end

    try
        R = realizer(P,mid)
        if verb
            println("confirmed")
        end
        return dimension_work(P,lb,mid,verb)
    catch
    end
    if verb
        println("none exists")
    end
    return dimension_work(P,mid+1,ub,verb)
end
