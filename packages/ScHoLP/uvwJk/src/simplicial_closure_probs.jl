export closure_type_counts3,
    closure_type_counts4,
    open_types3,
    open_types4,
    STRONG,
    WEAK,
    OPEN,
    simplex_key3,
    simplex_key4,
    newly_closed_types3,
    newly_closed_types4,
    initialize_type_counter3,
    initialize_type_counter4,
    triangle_counts

const STRONG = 2
const WEAK   = 1
const OPEN   = 0

simplex_key3(wij::Int64, wik::Int64, wjk::Int64) =
    sorted_tuple(min(wij, STRONG), min(wik, STRONG), min(wjk, STRONG))

function simplex_key4(wijk::Int64, wijl::Int64, wikl::Int64, wjkl::Int64,
                      num_edges::Int64)
    wijk = min(wijk, STRONG)
    wijl = min(wijl, STRONG)
    wikl = min(wikl, STRONG)
    wjkl = min(wjkl, STRONG)
    key = sort([wijk, wijl, wikl, wjkl], alg=InsertionSort)
    if     num_edges == 5; for j = 1:2; key[j] = -1; end
    elseif num_edges == 4; for j = 1:3; key[j] = -2; end
    elseif num_edges == 3; for j = 1:3; key[j] = -3; end
    end
    return tuple(key...)
end

function initialize_type_counter3()
    type_counts = counter(NTuple{3, Int64})
    for i = 0:2, j = i:2, k = j:2
        push!(type_counts, (i, j, k), 0)
    end
    return type_counts
end

function initialize_type_counter4()
    type_counts = counter(NTuple{4, Int64})
    for w1 = 0:2, w2 = w1:2, w3 = w2:2, w4 = w3:2
        push!(type_counts, (w1, w2, w3, w4), 0)  # All 6 edges
        push!(type_counts, (-1, -1, w3, w4), 0)  # Only 5 edges
        push!(type_counts, (-2, -2, -2, w4), 0)  # Only 4 edges
        push!(type_counts, (-3, -3, -3, w4), 0)  # Only 3 edges                    
    end
    return type_counts
end

function triangle_counts(simplices::Vector{Int64}, nverts::Vector{Int64})
    counts = counter(NTuple{3, Int64})
    curr_ind = 1
    for nvert in nverts
        simp = simplices[curr_ind:(curr_ind + nvert - 1)]
        curr_ind += nvert
        for (i, j, k) in combinations(simp, 3)
            if i == j || i == k || j == k; continue; end
            push!(counts, sorted_tuple(i, j, k))
        end
    end
    return counts
end

"""
triangle_counts
---------------

Counts the number of times each simplicial triangle appears in the data. This
function is expensive and requires storage on the order of the number of
triangles. Returns a counter that takes a sorted triple of indices as a key and
returns the count of that triangle.

triangle_counts(data::HONData)

Input parameters:
- data::HONData: The data.
"""
triangle_counts(data::HONData) =
    triangle_counts(data.simplices, data.nverts)


# Determine the type of every newly closed 4-node simplex.
function newly_closed_types4(old_simplices::Vector{Int64}, old_nverts::Vector{Int64},
                             new_simplices::Vector{Int64}, new_nverts::Vector{Int64})
    A_old, A_old_t, B_old = basic_matrices(old_simplices, old_nverts)
    simplex_order_old = simplex_degree_order(A_old_t)
    closed(i::Int64, j::Int64, k::Int64, l::Int64) =
        tetrahedron_closed(A_old, A_old_t, simplex_order_old, i, j, k, l)    
    n = size(B_old, 1)
    is_new_node = vec(sum(A_old_t, dims=1)) .== 0
    degs = vec(sum(make_sparse_ones(B_old), dims=1))    
    
    new_tetrahedra = Set{NTuple{4, Int64}}()
    type_counts = initialize_type_counter4()
    
    counts3 = triangle_counts(old_simplices, old_nverts)
    weight3(i::Int64, j::Int64, k::Int64) = counts3[sorted_tuple(i, j, k)]

    curr_ind = 1
    for nvert in new_nverts
        simp = new_simplices[curr_ind:(curr_ind + nvert - 1)]
        curr_ind += nvert
        for (i, j, k, l) in combinations(simp, 4)
            # SKIP if all 4 nodes are not unique
            if i == j || i == k || i == l || j == k || j == l || k == l; continue; end
            
            # SKIP if a node is new
            if max(i, j, k, l) > n; continue; end
            if any(is_new_node[[i, j, k, l]]); continue; end
            
            # SKIP if not at least one triangle
            Bo_ij, Bo_ik, Bo_il = B_old[i, j], B_old[i, k], B_old[i, l]
            Bo_jk, Bo_jl, Bo_kl = B_old[j, k], B_old[j, l], B_old[k, l]
            num_edges = sum([Bo_ij, Bo_ik, Bo_il, Bo_jk, Bo_jl, Bo_kl] .> 0)
            if num_edges < 3; continue; end
            ijk_tri = Bo_ij > 0 && Bo_ik > 0 && Bo_jk > 0
            ijl_tri = Bo_ij > 0 && Bo_il > 0 && Bo_jl > 0
            ikl_tri = Bo_ik > 0 && Bo_il > 0 && Bo_kl > 0
            jkl_tri = Bo_jk > 0 && Bo_jl > 0 && Bo_kl > 0
            if (ijk_tri + ijl_tri + ikl_tri + jkl_tri) < 1; continue; end

            # SKIP if already closed
            if num_edges == 6 && closed(i, j, k, l); continue; end
            
            # SKIP if we already processed the new closure
            key = sorted_tuple(i, j, k, l)
            if key in new_tetrahedra; continue; end
            push!(new_tetrahedra, key)

            wijk = weight3(i, j, k)
            wijl = weight3(i, j, l)
            wikl = weight3(i, k, l)
            wjkl = weight3(j, k, l)
            push!(type_counts, simplex_key4(wijk, wijl, wikl, wjkl, num_edges))
        end
    end
    
    return type_counts
end

# Get the number of open 4-node configurations of each type containing at least
# one triangle.
function open_types4(simplices::Vector{Int64}, nverts::Vector{Int64})
    A, At, B = basic_matrices(simplices, nverts)
    simplex_order  = simplex_degree_order(At)
    triangle_order = proj_graph_degree_order(B)
    n = size(B, 1)
    type_counts = initialize_type_counter4()
    counts3 = triangle_counts(simplices, nverts)
    weight3(i::Int64, j::Int64, k::Int64) = counts3[sorted_tuple(i, j, k)]

    # map of key to integer index
    tetra_index_map = Dict{NTuple{4, Int64}, Int64}()
    for w1 = 0:2, w2 = w1:2, w3 = w2:2, w4 = w3:2
        ind = length(tetra_index_map) + 1
        tetra_index_map[(w1, w2, w3, w4)] = ind
    end
    # thread-local counters
    nthreads = Threads.nthreads()
    all_tetra_counts_arr = Vector{Vector{Int64}}(undef, nthreads)
    open_tetra_counts_arr = Vector{Vector{Int64}}(undef, nthreads)
    Threads.@threads for i = 1:nthreads
        all_tetra_counts_arr[i] = zeros(Int64, length(tetra_index_map))
        open_tetra_counts_arr[i] = zeros(Int64, length(tetra_index_map))
    end

    # 1. Get 4-node, 6-edge counts, which must be induced by looping over all
    # 2-skeletons in the data.
    print(stdout, "tetrahedral counts...\n")
    shuffled_inds = collect(1:n)
    shuffle!(shuffled_inds)
    Threads.@threads for ii = 1:n
        i = shuffled_inds[ii]
        weight_arr = zeros(Int64, 4)
        if Threads.threadid() == 1
            print(stdout, "$(ii) of $n \r")
            flush(stdout)
        end
        nbrs = sort(neighbors(B, triangle_order, i), by=v->triangle_order[v])
        nnbr = length(nbrs)
        for jj in 1:nnbr
            j = nbrs[jj]
            for kk in (jj + 1):nnbr
                k = nbrs[kk]
                if B[j, k] == 0; continue; end
                weight_arr[1] = min(weight3(i, j, k), STRONG)
                for ll in (kk + 1):nnbr
                    l = nbrs[ll]
                    if B[j, l] > 0 && B[k, l] > 0
                        weight_arr[2] = min(weight3(i, j, l), STRONG)
                        weight_arr[3] = min(weight3(i, k, l), STRONG)
                        weight_arr[4] = min(weight3(j, k, l), STRONG)
                        key = NTuple{4,Int64}(sort(weight_arr, alg=InsertionSort))
                        index = tetra_index_map[key]
                        tid = Threads.threadid()
                        all_tetra_counts_arr[tid][index] += 1
                        if minimum(weight_arr) == 0 ||
                            !tetrahedron_closed(A, At, simplex_order, i, j, k, l)
                            open_tetra_counts_arr[tid][index] += 1
                        end
                    end
                end
            end
        end
    end

    all_tetra_counts  = sum(all_tetra_counts_arr)
    open_tetra_counts = sum(open_tetra_counts_arr)
    for (key, val) in tetra_index_map
        push!(type_counts, key, open_tetra_counts[val])
    end

    index_map = Dict{NTuple{4, Int64}, Int64}()
    for (ind, (key, _)) in enumerate(type_counts)
        index_map[key] = ind
    end

    # 2. Get 5-edge, 4-node (2 triangle) counts
    #
    # 2A. Form matrices whose (i, j) entry is number of triangles with a
    # particular weight containing i and j
    W_base = triu(make_sparse_ones(B))
    W0_all = Vector{SpIntMat}(undef, nthreads)
    W1_all = Vector{SpIntMat}(undef, nthreads)
    W2_all = Vector{SpIntMat}(undef, nthreads)
    Threads.@threads for i = 1:nthreads
        W0_all[i] = copy(W_base)
        W1_all[i] = copy(W_base)
        W2_all[i] = copy(W_base)
    end

    W_all = [W0_all, W1_all, W2_all]
    Threads.@threads for i = 1:n        
        for (j, k) in neighbor_pairs(B, triangle_order, i)
            if B[j, k] > 0
                weight = min(weight3(i, j, k), STRONG)
                a, b, c = sort([i, j, k], alg=InsertionSort)
                tid = Threads.threadid()
                W_all[weight + 1][tid][a, b] += 1
                W_all[weight + 1][tid][a, c] += 1
                W_all[weight + 1][tid][b, c] += 1                
            end
        end
    end

    # Every edge starts with a count of 1 to get the nonzero pattern correct.
    # Here, we subtract off that count.
    Threads.@threads for i = 1:nthreads
        W0_all[i].nzval .-= 1
        W1_all[i].nzval .-= 1
        W2_all[i].nzval .-= 1
    end
    W0, W1, W2 = sum(W0_all), sum(W1_all), sum(W2_all)
    # 2B. Get non-induced counts. Each edge contributes to a count for every
    # pair of triangles to which it is adjacent.
    #
    # Same triangle weight    
    for (i, W) in [(0, W0), (1, W1), (2, W2)]
        for k in 1:n, val in nz_row_vals(W, k)
            push!(type_counts, (-1, -1, i, i), binomial(val, 2))
        end
    end
    # Different triangle weights
    for (i, j, Wi, Wj) in [(0, 1, W0, W1), (0, 2, W0, W2), (1, 2, W1, W2)]
        for k in 1:n, (val, row) in zip(nz_row_vals(Wi, k), nz_row_inds(Wi, k))
            push!(type_counts, (-1, -1, i, j), val * Wj[row, k])
        end
    end

    for w1 = 0:2, w2 = w1:2, w3 = w2:2, w4 = w3:2
        count = all_tetra_counts[tetra_index_map[(w1, w2, w3, w4)]]
        for (wi, wj) in [(w1, w2), (w1, w3), (w1, w4), (w2, w3), (w2, w4), (w3, w4)]
            push!(type_counts, (-1, -1, wi, wj), -count)
        end
    end

    # 3. Triangles with an adjacent edge
    tri_adj_edge_counts_arr  = zeros(length(index_map), nthreads)
    degs = vec(sum(make_sparse_ones(B), dims=2))
    Threads.@threads for i = 1:n
        for (j, k) in neighbor_pairs(B, triangle_order, i)
            if B[j, k] > 0
                key = (-2, -2, -2, min(weight3(i, j, k), STRONG))
                count = degs[i] + degs[j] + degs[k] - 6
                tid = Threads.threadid()
                tri_adj_edge_counts_arr[index_map[key], tid] += count
            end
        end
    end
    tri_adj_edge_counts = sum(tri_adj_edge_counts_arr, dims=2)
    for (key, index) in index_map
        push!(type_counts, key, tri_adj_edge_counts[index])
    end
    # 3A. Each triangle in every 5-edge pattern contributed 2 too many
    for w1 = 0:2, w2 = w1:2
        count = type_counts[(-1, -1, w1, w2)]
        push!(type_counts, (-2, -2, -2, w1), -2 * count)
        push!(type_counts, (-2, -2, -2, w2), -2 * count)    
    end
    # 3B. Each triangle in every tetrahedron contributes 3 too many
    for w1 = 0:2, w2 = w1:2, w3 = w2:2, w4 = w3:2    
        count = all_tetra_counts[tetra_index_map[(w1, w2, w3, w4)]]
        for w in [w1, w2, w3, w4]
            push!(type_counts, (-2, -2, -2, w), -3 * count)
        end
    end

    # 4. Triangles with an isolated node
    tri_iso_node_counts_arr  = zeros(length(index_map), nthreads)
    num_verts = sum(sum(At, dims=1) .> 0)
    Threads.@threads for i = 1:n
       for (j, k) in neighbor_pairs(B, triangle_order, i)
           if B[j, k] > 0
               key = (-3, -3, -3, min(weight3(i, j, k), STRONG))
               tid = Threads.threadid()               
               tri_iso_node_counts_arr[index_map[key], tid] += (num_verts - 3)
           end
       end
    end
    tri_iso_node_counts = sum(tri_iso_node_counts_arr, dims=2)
    for (key, index) in index_map
        push!(type_counts, key, tri_iso_node_counts[index])
    end
        
    # Subtract off other induced patterns
    #   --tetrahedra
    for w1 = 0:2, w2 = w1:2, w3 = w2:2, w4 = w3:2    
        count = all_tetra_counts[tetra_index_map[(w1, w2, w3, w4)]]
        for w in [w1, w2, w3, w4]
            push!(type_counts, (-3, -3, -3, w), -count)
        end
    end
    #   --5-edge
    for w1 = 0:2, w2 = w1:2
        count = type_counts[(-1, -1, w1, w2)]
        push!(type_counts, (-3, -3, -3, w1), -count)
        push!(type_counts, (-3, -3, -3, w2), -count)
    end
    #   --Triangle plus adjacent edge
    for w = 0:2
        count = type_counts[(-2, -2, -2, w)]
        push!(type_counts, (-3, -3, -3, w), -count)
    end

    return type_counts
end

# Determine the previous topology of newly filled triangles.
function newly_closed_types3(old_simplices::Vector{Int64}, old_nverts::Vector{Int64},
                             new_simplices::Vector{Int64}, new_nverts::Vector{Int64})
    A_old, A_old_t, B_old = basic_matrices(old_simplices, old_nverts)
    simplex_order_old = simplex_degree_order(A_old_t)
    closed(i::Int64, j::Int64, k::Int64) =
        triangle_closed(A_old, A_old_t, simplex_order_old, i, j, k)
    n = size(B_old, 1)
    is_new_node = vec(sum(A_old_t, dims=1)) .== 0    

    type_counts = initialize_type_counter3()
    new_triangles = Set{NTuple{3, Int64}}()

    # Loop over simplices for closed triangles
    curr_ind = 1
    for nvert in new_nverts
        simp = new_simplices[curr_ind:(curr_ind + nvert - 1)]
        curr_ind += nvert
        for (i, j, k) in combinations(simp, 3)
            # SKIP if any duplicates
            if i == j || i == k || j == k; continue; end
            # SKIP if 0-simplex is missing
            if max(i, j, k) > n || any(is_new_node[[i, j, k]]); continue; end
            # SKIP if the triangle was closed before
            wij, wik, wjk = B_old[i, j], B_old[i, k], B_old[j, k]
            if min(wij, wik, wjk) > 0 && closed(i, j, k); continue; end
            # SKIP if we have already looked at this triangle
            tri_key = sorted_tuple(i, j, k)
            if tri_key in new_triangles; continue; end
            push!(new_triangles, tri_key)
            # update type counts
            push!(type_counts, simplex_key3(wij, wik, wjk))
        end
    end

    return type_counts
end

# Get the number of open triangles for each type.
function open_types3(simplices::Vector{Int64}, nverts::Vector{Int64})
    A, At, B = basic_matrices(simplices, nverts)
    simplex_order  = simplex_degree_order(At)
    triangle_order = proj_graph_degree_order(B)
    n = size(B, 1)

    # Setup counts data structure
    type_counts = initialize_type_counter3()    

    index_map = Dict{NTuple{3, Int64}, Int64}()
    for (ind, (key, _)) in enumerate(type_counts)
        index_map[key] = ind
    end
    
    # Get triangle counts
    all_tris_counts_arr  = zeros(length(index_map), n)
    open_tris_counts_arr = zeros(length(index_map), n)
    Threads.@threads for i = 1:n
        curr_triangle_order = triangle_order[i]
        nbrs = Int64[]
        weights = Int64[]
        for (nbr, weight) in zip(nz_row_inds(B, i), nz_row_vals(B, i))
            if triangle_order[nbr] > curr_triangle_order
                push!(nbrs, nbr)
                push!(weights, weight)
            end
        end        
        nnbr = length(nbrs)
        for jj = 1:nnbr, kk = (jj+1):nnbr
            j, k = nbrs[[jj, kk]]
            wij, wik = weights[[jj, kk]]
            wjk = B[j, k]
            if wjk > 0
                tri_ind = index_map[simplex_key3(wij, wik, wjk)]
                all_tris_counts_arr[tri_ind, i] += 1                    
                if !triangle_closed(A, At, simplex_order, i, j, k)
                    open_tris_counts_arr[tri_ind, i] += 1
                end
            end
        end
    end
    all_tris_counts  = sum(all_tris_counts_arr, dims=2)
    open_tris_counts = sum(open_tris_counts_arr, dims=2)
    triad_types = [(WEAK, WEAK, WEAK), (WEAK, WEAK, STRONG),
                   (WEAK, STRONG, STRONG), (STRONG, STRONG, STRONG)]
    for key in triad_types
        push!(type_counts, key, open_tris_counts[index_map[key]])
    end

    # strong and weak degree counts
    d1, d2 = Int64[], Int64[]
    for i = 1:n
        weights = nz_row_vals(B, i)
        push!(d1, sum(weights .== 1))
        push!(d2, sum(weights .>  1))
    end

    # wedge counts
    push!(type_counts, (OPEN, WEAK,   WEAK),   sum(binomial.(d1, 2)))
    push!(type_counts, (OPEN, STRONG, STRONG), sum(binomial.(d2, 2)))
    push!(type_counts, (OPEN, WEAK,   STRONG), sum(d1 .* d2))
    for triad_key in triad_types
        count = all_tris_counts[index_map[triad_key]]
        for (w1, w2) in combinations(triad_key, 2)
            push!(type_counts, simplex_key3(OPEN, w1, w2), -count)
        end
    end

    # Edge + isolated node counts
    num_verts = sum(sum(At, dims=1) .> 0)
    push!(type_counts, (OPEN, OPEN, WEAK),   (sum(d1) / 2) * (num_verts - 2))
    push!(type_counts, (OPEN, OPEN, STRONG), (sum(d2) / 2) * (num_verts - 2))
    for triad_key in triad_types
        count = all_tris_counts[index_map[triad_key]]
        for w in triad_key
            push!(type_counts, (OPEN, OPEN, w), -count)
        end
    end
    for w1 = 1:2, w2 = w1:2
        count = type_counts[(OPEN, w1, w2)]
        for w in [w1, w2]
            push!(type_counts, (OPEN, OPEN, w), -count)
        end
    end

    # Empty subgraphs
    push!(type_counts, (OPEN, OPEN, OPEN), binomial(num_verts, 3))
    push!(type_counts, (OPEN, OPEN, OPEN), -sum(all_tris_counts))
    for key in [(OPEN, OPEN, WEAK), (OPEN, OPEN, STRONG),
                (OPEN, WEAK, WEAK), (OPEN, WEAK, STRONG), (OPEN, STRONG, STRONG)]
        push!(type_counts, (OPEN, OPEN, OPEN), -type_counts[key])
    end
    return type_counts
end

"""
closure_type_counts3
--------------------

Computes the closure probabilities of all 3-node configurations. The closure
probability is the fraction of instances of open configurations appearing in the
first 80% of the timestamped simplices that appear in a simplex in the final
20%.

closure_type_counts3(dataset::HONData, initial_cutoff::Int64=100)

Input parameters:
- dataset::String: The dataset name.
- initial_cutoff::Int64=100: Initial cutoff of the simplices. If this is set to less than 100, then the data is first preprocessed to only consider the first initial_cutoff percentage of the data.
"""
function closure_type_counts3(dataset::HONData, initial_cutoff::Int64=100)
    simps = dataset.simplices
    nverts = dataset.nverts
    times = dataset.times
    if initial_cutoff < 100
        cutoff_percentile = convert(Int64, round(percentile(times, initial_cutoff)))
        simps, nverts, times = window_data(minimum(times), cutoff_percentile,
                                           simps, nverts, times)
    end
    old_simps, old_nverts, new_simps, new_nverts =
        split_data(simps, nverts, times, 80, 100)
    closed_type_counts =
        newly_closed_types3(old_simps, old_nverts, new_simps, new_nverts)
    open_type_counts = open_types3(old_simps, old_nverts)
    type_counts = [(k..., cnt, closed_type_counts[k]) for (k, cnt) in open_type_counts]
    writedlm("$(dataset.name)-3-node-closures-$(initial_cutoff).txt", sort(type_counts))
end

"""
closure_type_counts4
--------------------

Computes the closure probabilities of all 4-node configurations that contain at
least one triangle. The closure probability is the fraction of instances of open
configurations appearing in the first 80% of the timestamped simplices that
appear in a simplex in the final 20%.

closure_type_counts4(dataset::HONData, initial_cutoff::Int64=100)

Input parameters:
- dataset::HONData: The dataset.
- initial_cutoff::Int64=100: Initial cutoff of the simplices. If this is set to less than 100, then the data is first preprocessed to only consider the first initial_cutoff percentage of the data. 
"""
function closure_type_counts4(dataset::HONData, initial_cutoff::Int64=100)
    simps  = dataset.simplices
    nverts = dataset.nverts
    times  = dataset.times
    if initial_cutoff < 100
        cutoff_percentile = convert(Int64, round(percentile(times, initial_cutoff)))
        simps, nverts, times = window_data(minimum(times), cutoff_percentile,
                                           simps, nverts, times)
                                           
    end
    old_simps, old_nverts, new_simps, new_nverts =
        split_data(simps, nverts, times, 80, 100)
    closed_type_counts =
        newly_closed_types4(old_simps, old_nverts, new_simps, new_nverts)
    open_type_counts = open_types4(old_simps, old_nverts)
    type_counts = [(k..., cnt, closed_type_counts[k]) for (k, cnt) in open_type_counts]    
    writedlm("$(dataset.name)-4-node-closures-$(initial_cutoff).txt", sort(type_counts))
end
