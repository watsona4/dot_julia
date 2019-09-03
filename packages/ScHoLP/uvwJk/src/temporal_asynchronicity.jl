export interval_overlaps

function intervals(dataset::HONData)
    simplices, nverts, times = dataset.simplices, dataset.nverts, dataset.times
    I, J, T = Int64[], Int64[], Int64[]
    curr_ind = 1
    for (nv, time) in zip(nverts, times)
        simplex = simplices[curr_ind:(curr_ind + nv - 1)]
        curr_ind += nv
        for (i, j) in combinations(simplex, 2)
            push!(I, i)
            push!(J, j)
            push!(T, time)
        end
    end
    sp = sortperm(I)
    I, J, T = I[sp], J[sp], T[sp]
    
    minmax_I = Int64[]
    minmax_J = Int64[]
    min_V = Int64[]
    max_V = Int64[]    
    curr_ind = 1
    while curr_ind <= length(T)
        curr_i = I[curr_ind]
        curr_j = J[curr_ind]
        ijtimes = Int64[]
        # Gather timestamps until next static edge
        while curr_ind <= length(T) && I[curr_ind] == curr_i && J[curr_ind] == curr_j
            push!(ijtimes, T[curr_ind])
            curr_ind += 1
        end
        push!(minmax_I, curr_i)
        push!(minmax_J, curr_j)
        push!(min_V, minimum(ijtimes))
        push!(max_V, maximum(ijtimes))        
    end

    n = maximum(simplices)
    min_M = convert(SpIntMat, sparse(minmax_I, minmax_J, min_V, n, n))
    max_M = convert(SpIntMat, sparse(minmax_I, minmax_J, max_V, n, n))                   
    return (min_M, max_M)
end

"""
interval_overlaps
--------------------

interval_overlaps(dataset::HONData)

Compute the number of active interval overlaps in open triangles.

dataset::HONData
    The dataset.
"""
function interval_overlaps(dataset::HONData)
    min_M, max_M = intervals(dataset)
    A, At, B = basic_matrices(dataset)
    simplex_order = simplex_degree_order(At)
    triangle_order = proj_graph_degree_order(B)
    
    n = size(B)[2]
    overlaps = zeros(Int64, 4, n)    
    Threads.@threads for i = 1:n                           
        for (j, k) in neighbor_pairs(B, triangle_order, i)
            if B[j, k] > 0 && !triangle_closed(A, At, simplex_order, i, j, k)
                tij1, tij2 = min(min_M[i, j], min_M[j, i]), max(max_M[i, j], max_M[j, i])
                tik1, tik2 = min(min_M[i, k], min_M[k, i]), max(max_M[i, k], max_M[k, i])
                tjk1, tjk2 = min(min_M[j, k], min_M[k, j]), max(max_M[j, k], max_M[k, j])
                
                # Whether or not each interval overlaps
                ij_ik_ol = tij1 <= tik2 && tik1 <= tij2
                ij_jk_ol = tij1 <= tjk2 && tjk1 <= tij2
                ik_jk_ol = tik1 <= tjk2 && tjk1 <= tik2
                num_overlap = ij_ik_ol + ij_jk_ol + ik_jk_ol
                
                overlaps[num_overlap + 1, i] += 1
            end
        end
    end

    overlaps = sum(overlaps, dims=2)
    tot = sum(overlaps)
    frac_overlaps = overlaps / tot
    println("dataset & # open triangles & 0 overlaps & 1 overlap & 2 overlaps & 3 overlaps")
    println(@sprintf("%s & %d & %0.3f & %0.3f & %0.3f & %0.3f", dataset.name, tot, frac_overlaps...))
end
