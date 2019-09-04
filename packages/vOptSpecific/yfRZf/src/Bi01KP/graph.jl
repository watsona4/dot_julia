# MIT License
# Copyright (c) 2017: Xavier Gandibleux, Anthony Przybylski, Gauthier Soleilhac, and contributors.
struct graph
    pb::problem
    mono_pb::mono_problem
    layer::Vector{vertex} #last layer of the graph
end
Base.isempty(g::graph) = isempty(g.layer)

function build_graph(Δ::Triangle, output::Bool)
    xr = Δ.xr
    xs = Δ.xs
    pb = xr.pb
    λ1, λ2 = Δ.λ
    mono_pb = mono_problem(pb, λ1, λ2)
    # @assert obj(solve_mono(mono_pb)) == Δ.ub "$xr => $xs isn't a supporting edge of Y ($(solution(pb,solve_mono(mono_pb))))"
    reduce!(mono_pb, Δ, output)
    size(mono_pb) == 0 && return graph(pb, mono_pb, vertex[])
    
    s = source(mono_pb)

    current_layer = [s]
    for l = 1:size(mono_pb)
        
        # @assert mono_pb.variables[l] == current_layer[1].i
        # @assert l == current_layer[1].layer

        previous_layer = current_layer
        current_layer = vertex[]

        #Adds all vertices in the next layer obtained without picking the object
        for v in previous_layer
            if relax(v, mono_pb) >= Δ.lb #&& relax_z1(v, sortperm_z1) >= obj_1(xr) || relax_z2(v, sortperm_z2) >= obj_2(xs)
                push!(current_layer, vertex_skip(v, mono_pb))
            end
        end

        #Adds all vertices in the next layer obtained by picking the object (if possible)
        for v in previous_layer

            let wplus1 = v.w + pb.w[v.i] #Calculate the weight of the solution when we pick item i
                wplus1 > mono_pb.c && continue #If the solution is too heavy for the knapsack, skip it.
                child = vertex_keep(v, mono_pb) #else, create the vertex

                # Check if a node with that weight already exists so we can merge them.
                # The nodes in the layer are sorted by their weight so we can use a dichotomic search
                range = searchsorted(current_layer, wplus1, lt = weight_lt) # (weight_lt compares a vertex to an Integer weight)
                if isempty(range)
                    # ∄ node with that weight, we can add it (at the right place) to the current layer
                    insert!(current_layer, range.start , child)
                else
                    # a node with this weight already exists, we merge them
                    merge!(current_layer[range.start], child)
                end
            end
        end
    end
    return graph(pb, mono_pb, current_layer)
end

#Calculates the relaxation for the combined problem
function relax(v::vertex, mpb::mono_problem)

    #we assume the items are already sorted by utility
    #we only consider picking items which come after v.i

    vars = view(variables(mpb), v.layer+1:size(mpb))::SubArray{Int}
    zλ= v.zλ
    w = v.w
    c = mpb.c
    i = 1

    while i <= length(vars) && w + mpb.w[vars[i]] <= c
        var = vars[i]
        w += mpb.w[var]
        zλ += mpb.p[var]
        i += 1
    end

    if i <= length(vars) && length(vars) > 1
        cleft = mpb.c - w
        if i == 1
            varplus1 = vars[i+1]
            zλ += floor(Int, cleft * mpb.p[varplus1]/mpb.w[varplus1])
        elseif i == length(vars)
            varminus1 = vars[i-1]
            zλ += floor(Int, mpb.p[var] - (mpb.w[var] - cleft)*(mpb.p[varminus1]/mpb.w[varminus1]))
        else
            var = vars[i]
            varplus1 = vars[i+1]
            varminus1 = vars[i-1]
            U0 = zλ + floor(Int, cleft * mpb.p[varplus1]/mpb.w[varplus1])
            U1 = zλ + floor(Int, mpb.p[var] - (mpb.w[var] - cleft)*(mpb.p[varminus1]/mpb.w[varminus1]))
            zλ = max(U0,U1)
        end
    end

    return zλ
end