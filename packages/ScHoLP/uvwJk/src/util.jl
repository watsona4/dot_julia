export HONData,
    SpIntMat,
    SpFltMat,
    example_dataset,
    NbrSetMap,
    common_neighbors_map,
    neighbor_pairs,
    num_open_closed_triangles,
    sorted_tuple,
    enum_open_triangles,
    new_closures,
    make_sparse_ones,    
    basic_matrices,
    simplex_degree_order,
    proj_graph_degree_order,
    nz_row_inds,
    remove_diagonal,
    split_data,
    triangle_closed,
    tetrahedron_closed
    

"""
example_dataset
---------------

Returns one of the example datasets.

example_dataset(dataset::String)

Input parameter:
- dataset::String: one of "email-Enron", "contact-primary-school", "contact-high-school", "example1", or "example2"

"""
function example_dataset(dataset::String)
    if !(dataset in ["email-Enron", "contact-primary-school", "contact-high-school", "example1", "example2"])
        error("Unknown dataset $dataset")
    end
    dir = joinpath(dirname(dirname(@__FILE__)),"data")
    read(filename::String) = convert(Vector{Int64}, readdlm(filename, Int64)[:, 1])
    return HONData(read("$(dir)/$(dataset)/$(dataset)-simplices.txt"),
                   read("$(dir)/$(dataset)/$(dataset)-nverts.txt"),
                   read("$(dir)/$(dataset)/$(dataset)-times.txt"),
                   dataset)
end

"""
SpIntMat
--------

const SpIntMat = SparseMatrixCSC{Float64,Int64}
"""
const SpIntMat = SparseMatrixCSC{Int64,Int64}

"""
SpFltMat
--------

const SpFltMat = SparseMatrixCSC{Float64,Int64}
"""
const SpFltMat = SparseMatrixCSC{Float64,Int64}

"""
SpMat
--------

const SpMat = Union{SpIntMat,SpFltMat}
"""
const SpMat = Union{SpIntMat,SpFltMat}

"""
NbrSetMap
--------

const NbrSetMap = Dict{NTuple{2, Int64}, Set{Int64}}
"""
const NbrSetMap = Dict{NTuple{2, Int64}, Set{Int64}}

"""
HONData
-------

Data structure for a temporal higher-order network.

Each dataset consists of three integer vectors: simplices, nverts, and times. 
- The simplices is a contiguous vector of nodes comprising the simplices. 
- The nverts vector contains the number of vertices within each simplex. 
- The times vector contains the timestamps of the simplices (same length as nverts).

For example, consider a dataset consisting of three simplices:

    1. {1, 2, 3} at time 10
    2. {2, 4} at time 15.
    3. {1, 3, 4, 5} at time 21.

Then the data structure would be  
- simplices = [1, 2, 3, 2, 4, 1, 3, 4, 5]
- nverts = [3, 2, 4]
- times = [10, 15, 21]
There is an additional name variable attached to the dataset.
"""
struct HONData
    simplices::Vector{Int64}
    nverts::Vector{Int64}
    times::Vector{Int64}
    name::String
end

""" 
common_neighbors_map
-------------------

Construct a map where a key is an edge in the graph B participating in at least
one triangle of interest and a value is the vector of common neighbors of the
end points of the edge. The graph B is assumed to be undirected, and the keys
are ordered by the pair with smallest ID first.

common_neighbors_map(B::SpIntMat, triangles::Vector{NTuple{3,Int64}})

Input parameters:
- B::SpIntMat: the graph
- triangles::Vector{NTuple{3,Int64}}: the triangles of interest
"""
function common_neighbors_map(B::SpIntMat, triangles::Vector{NTuple{3,Int64}})
    I = zeros(Int64, 3 * length(triangles))
    J = zeros(Int64, 3 * length(triangles))
    Threads.@threads for ind = 1:length(triangles)
        (i, j, k) = triangles[ind]
        ran = ((ind - 1) * 3 + 1):(ind * 3)
        a, b, c = sort([i, j, k], alg=InsertionSort)
        I[ran] = [a, a, b]
        J[ran] = [b, c, c]
    end
    n = size(B, 2)
    T = sparse(I, J, ones(length(I)), n, n)

    nthreads = Threads.nthreads()
    common_nbrs_vec = Vector{NbrSetMap}(undef, nthreads)
    Threads.@threads for tid = 1:nthreads
        common_nbrs_vec[tid] = NbrSetMap()
    end
    
    Threads.@threads for j = 1:n
        tid = Threads.threadid()            
        if tid == 1
            print(stdout, "$j of $n \r")
            flush(stdout)
        end
        Bj = Set{Int64}(nz_row_inds(B, j))
        # only collect data on edges that appear in triangles
        for i in filter(v -> (v < j) && T[v, j] > 0, Bj)
            Bi = Set{Int64}(nz_row_inds(B, i))
            common_nbrs_vec[tid][(i, j)] = intersect(Bi, Bj)
        end
    end

    # Combine the maps
    common_nbrs = common_nbrs_vec[1]
    for tid = 2:nthreads
        for (key, val) in common_nbrs_vec[tid]
            common_nbrs[key] = val
        end
    end
    return common_nbrs
end

function new_closures(old_simplices::Vector{Int64}, old_nverts::Vector{Int64},
                      new_simplices::Vector{Int64}, new_nverts::Vector{Int64})
    A_old, A_old_t, B_old = basic_matrices(old_simplices, old_nverts)
    simp_order = simplex_degree_order(A_old_t)
    n = size(B_old, 1)
    is_new_node = sum(A_old_t, dims=1) .== 0
    new_triangles = Set{NTuple{3,Int64}}()

    curr_ind = 1
    for nvert in new_nverts
        simp = new_simplices[curr_ind:(curr_ind + nvert - 1)]
        curr_ind += nvert
        for (i, j, k) in combinations(simp, 3)
            # SKIP if any duplicates
            if i == j || i == k || j == k; continue; end
            # SKIP if 0-simplex is missing
            if max(i, j, k) > n || any(is_new_node[[i, j, k]]); continue; end
            # SKIP if already closed
            if triangle_closed(A_old, A_old_t, simp_order, i, j, k); continue; end
            # SKIP if we have already looked at this triangle
            tri_key = sorted_tuple(i, j, k)
            if tri_key in new_triangles; continue; end
            # Newly closed triangle
            push!(new_triangles, tri_key)
        end
    end

    return new_triangles
end

function enum_open_triangles(simplices::Vector{Int64}, nverts::Vector{Int64})
    A, At, B = basic_matrices(simplices, nverts)
    simp_order = simplex_degree_order(At)
    tri_order = proj_graph_degree_order(B)
    n = size(B, 2)

    nthreads = Threads.nthreads()
    triangles = Vector{Vector{NTuple{3,Int64}}}(undef, nthreads)
    for i in 1:nthreads; triangles[i] = Vector{NTuple{3,Int64}}(); end

    # Shuffle so that data better distributes over threads
    shuffled_inds = shuffle(collect(1:n))
    Threads.@threads for ii = 1:length(shuffled_inds)
        tid = Threads.threadid()
        i = shuffled_inds[ii]
        for (j, k) in neighbor_pairs(B, tri_order, i)
            if B[j, k] > 0 && !triangle_closed(A, At, simp_order, i, j, k)                
                push!(triangles[tid], (i, j, k))
            end
        end
    end

    # Combine arrays
    total = sum([length(ti) for ti in triangles])
    combined_triangles = Vector{NTuple{3,Int64}}(undef, total)
    curr_ind = 1
    for i in 1:nthreads
        size = length(triangles[i])
        combined_triangles[curr_ind:(curr_ind + size - 1)] = triangles[i][:]
        curr_ind += size
    end
    return combined_triangles
end

""" Turns 3 integers into a sorted tuple. """
sorted_tuple(a::Int64, b::Int64, c::Int64) =
    NTuple{3, Int64}(sort([a, b, c], alg=InsertionSort))
""" Turns 4 integers into a sorted tuple. """
sorted_tuple(a::Int64, b::Int64, c::Int64, d::Int64) =
    NTuple{4, Int64}(sort([a, b, c, d], alg=InsertionSort))

function bipartite_graph(simplices::Vector{Int64}, nverts::Vector{Int64})
    if length(simplices) == 0
        return convert(SpIntMat, sparse([], [], []))
    end
    I, J = Int64[], Int64[]
    curr_ind = 1
    for (simplex_ind, nv) in enumerate(nverts)
        for vert in simplices[curr_ind:(curr_ind + nv - 1)]
            push!(I, vert)
            push!(J, simplex_ind)
        end
        curr_ind += nv
    end
    return convert(SpIntMat, sparse(I, J, 1, maximum(simplices), length(nverts)))
end

"""
basic_matrices
--------------

Computes some simple matrices associated with a dataset.

basic_matrices(simplices::Vector{Int64}, nverts::Vector{Int64})

Input parameters:
- simplices::Vector{Int64}: the contiguous vector of simplices
- nverts::Vector{Int64}: the vector of sizes of simplices

Outputs tuple (A, At, B):
- A::SpIntMat: (# nodes) x (# simplices) adjacency matrix
- At::SpIntMat: the transpose of A
- B::SpIntMat: Projected graph as a Sparse integer matrix, where B[i, j] is the number of times that i and j co-appear in a simplex.
"""
function basic_matrices(simplices::Vector{Int64}, nverts::Vector{Int64})
    A = bipartite_graph(simplices, nverts)
    At = A'
    B = A * At
    B -= sparse(Diagonal(B))
    dropzeros!(B)
    return (A, convert(SpIntMat, At), B)
end

"""
basic_matrices
--------------

Computes some simple matrices associated with a dataset.

basic_matrices(dataset::HONData)

Input parameter:
- dataset::HONData: the dataset

Outputs tuple (A, At, B):
- A::SpIntMat: (# nodes) x (# simplices) adjacency matrix
- At::SpIntMat: the transpose of A
- B::SpIntMat: Projected graph as a Sparse integer matrix, where B[i, j] is the number of times that i and j co-appear in a simplex.
"""
basic_matrices(dataset::HONData) =
    basic_matrices(dataset.simplices, dataset.nverts)

nz_row_inds(A::SpIntMat, ind::Int64) = A.rowval[A.colptr[ind]:(A.colptr[ind + 1] - 1)]
nz_row_inds(A::SpFltMat, ind::Int64) = A.rowval[A.colptr[ind]:(A.colptr[ind + 1] - 1)]
nz_row_vals(A::SpIntMat, ind::Int64) = A.nzval[A.colptr[ind]:(A.colptr[ind + 1] - 1)]
nz_row_vals(A::SpFltMat, ind::Int64) = A.nzval[A.colptr[ind]:(A.colptr[ind + 1] - 1)]

"""
triangle_closed
--------------

Checks if a triangle is closed.

triangle_closed(A::SpIntMat, At::SpIntMat, order::Vector{Int64},
                i::Int64, j::Int64, k::Int64)

Input parameter:
- A::SpIntMat: (# nodes) x (# simplices) adjacency matrix
- At::SpIntMat: the transpose of A
- order::Vector{Int64}: ordering of the nodes
- i::Int64: first node
- j::Int64: second node
- k::Int64: third node

Outputs true or false for closed or open triangle
"""
function triangle_closed(A::SpIntMat, At::SpIntMat, order::Vector{Int64},
                         i::Int64, j::Int64, k::Int64)
    ind, nbr1, nbr2 = sort([i, j, k], by=(v -> order[v]), alg=InsertionSort)
    # Search all simplices of least common vertex
    for simplex_id in nz_row_inds(At, ind)
        if A[nbr1, simplex_id] > 0 && A[nbr2, simplex_id] > 0
            return true
        end
    end
    return false
end

"""
tetrahedron_closed
--------------

Checks if a tetrahedron is closed.

tetrahedron_closed(A::SpIntMat, At::SpIntMat, order::Vector{Int64},
                   i::Int64, j::Int64, k::Int64, l::Int64)

Input parameter:
- A::SpIntMat: (# nodes) x (# simplices) adjacency matrix
- At::SpIntMat: the transpose of A
- order::Vector{Int64}: ordering of the nodes
- i::Int64: first node
- j::Int64: second node
- k::Int64: third node
- l::Int64: fourth node

Outputs true or false for closed or open tetrahedron
"""
function tetrahedron_closed(A::SpIntMat, At::SpIntMat, order::Vector{Int64},
                            i::Int64, j::Int64, k::Int64, l::Int64)
    ind, nbr1, nbr2, nbr3 = sort([i, j, k, l], by=(v -> order[v]), alg=InsertionSort)
    # Search all simplices of least common vertex
    for simplex_id in nz_row_inds(At, ind)
        if A[nbr1, simplex_id] > 0 && A[nbr2, simplex_id] > 0 && A[nbr3, simplex_id] > 0
            return true
        end
    end
    return false
end

"""
make_sparse_ones
---------------

Returns a new sparse matrix with the same non-zero pattern as the input but
where all non-zeros are set to 1.

make_sparse_ones(A::SpIntMat)

Input parameter:
- A::SpIntMat: a sparse matrix
"""
function make_sparse_ones(A::SpMat)
    C = copy(A)
    LinearAlgebra.fillstored!(C, 1)
    return C
end

function neighbors(B::SpIntMat, order::Vector{Int64}, node::Int64)
    node_order = order[node]
    return filter(nbr -> order[nbr] > node_order, nz_row_inds(B, node))
end

neighbor_pairs(B::SpIntMat, order::Vector{Int64}, node::Int64) =
    combinations(neighbors(B, order, node), 2)

""" Ordering of nodes by the number of simplices in which they appear """
function simplex_degree_order(At::SpIntMat)
    n = size(At, 2)
    simplex_order = zeros(Int64, n)
    simplex_order[sortperm(vec(sum(At, dims=1)))] = collect(1:n)
    return simplex_order
end

""" Ordering of nodes by their degree """
function proj_graph_degree_order(B::SpIntMat)
    n = size(B, 1)
    triangle_order = zeros(Int64, n)
    triangle_order[sortperm(vec(sum(make_sparse_ones(B), dims=1)))] = collect(1:n)
    return triangle_order
end

function num_open_closed_triangles(A::SpIntMat, At::SpIntMat, B::SpIntMat)
    simp_order = simplex_degree_order(At)
    tri_order = proj_graph_degree_order(B)
    n = size(B, 2)
    counts = zeros(Int64, 2, Threads.nthreads())
    Threads.@threads for i = 1:n
        for (j, k) in neighbor_pairs(B, tri_order, i)
            if B[j, k] > 0
                tid = Threads.threadid()
                closed = triangle_closed(A, At, simp_order, i, j, k)
                counts[1 + closed, tid] += 1
            end
        end
    end
    return tuple(vec(sum(counts, dims=2))...)
end

"""
num_open_closed_triangles
-------------------------

Computes the number of open and closed triangles in a dataset.

num_open_closed_triangles(data::HONData)

Input parameter:
- data::HONData: the dataset

Outputs tuple (no, nc):
- no: number of open triangles
- nc: number of closed triangles
"""
num_open_closed_triangles(data::HONData) =
    num_open_closed_triangles(basic_matrices(data)...)

# Get events in the [start_time, end_time] interval
function window_data(start_time::Int64, end_time::Int64, simplices::Vector{Int64},
                     nverts::Vector{Int64}, times::Vector{Int64})
    curr_ind = 1
    window_simplices, window_nverts, window_times = Int64[], Int64[], Int64[]
    for (nv, time) in zip(nverts, times)
        end_ind = curr_ind + nv - 1
        if time >= start_time && time <= end_time
            push!(window_nverts, nv)
            push!(window_times, time)
            append!(window_simplices, simplices[curr_ind:end_ind])
        end
        curr_ind += nv
    end
    return (window_simplices, window_nverts, window_times)
end

"""
split_data
----------

Split data by timestamps into quantiles specified by quantile1 and
quantile2. Returns a 4-tuple (old_simps, old_nverts, new_simps, new_nverts),
where (old_simps, old_nverts) are the data in the quantile [0, quantile1]
and (new_simps, new_nverts) are the data in the quantile (quantile1, quantile2].

split_data(simplices::Vector{Int64}, nverts::Vector{Int64},
           times::Vector{Int64}, quantile1::Int64,
           quantile2::Int64)

Input parameters:
- simplices::Vector{Int64}: contiguous vector of simplices from dataset
- nverts::Vector{Int64}: vector of simplex sizes from dataset
- times::Vector{Int64}: vector of timestamps of simplices
- quantile1::Int64: first quantile
- quantile2::Int64: second quantile

Returns a tuple (old_simps, old_nverts, new_simps, new_nverts):
- old_simplices::Vector{Int64}: simplices in quantile1
- old_nverts::Vector{Int64}: sizes of simplices in old_simplices
- new_simplices::Vector{Int64}: simplices between quantile1 and quantile 2
- new_nverts::Vector{Int64}: sizes of simplices in new_simplices
"""
function split_data(simplices::Vector{Int64}, nverts::Vector{Int64},
                    times::Vector{Int64}, quantile1::Int64,
                    quantile2::Int64)
    if quantile1 > quantile2
        error("First quantile ($quantile1) needs to be <= second quantile ($quantile2)")
    end
    cutoff(prcntl::Int64) = convert(Int64, round(percentile(times, prcntl)))

    cutoff1 = cutoff(quantile1)
    old_simps, old_nverts =
        window_data(minimum(times), cutoff1, simplices, nverts, times)[1:2]

    cutoff2 = (quantile2 == 100) ? (maximum(times) + 1) : cutoff(quantile2)
    new_simps, new_nverts =
        window_data(cutoff1 + 1, cutoff2, simplices, nverts, times)[1:2]

    return old_simps, old_nverts, new_simps, new_nverts
end

function backbone(simplices::Vector{Int64}, nverts::Vector{Int64},
                  times::Vector{Int64})
    # backbone data
    bb_simplices, bb_nverts, bb_times = Int64[], Int64[], Int64[]
    
    # contains for all simplices
    max_size = maximum(nverts)
    all_simplices = Vector{Set}(undef, max_size)
    for i in 1:max_size; all_simplices[i] = Set{Any}(); end

    curr_ind = 1
    for (nvert, time) in zip(nverts, times)
        simplex = simplices[curr_ind:(curr_ind + nvert - 1)]
        nvert = length(simplex)
        # Add to data if we have not seen it yet
        if !(simplex in all_simplices[nvert])
            push!(all_simplices[nvert], simplex)
            # add to backbone
            append!(bb_simplices, simplex)
            push!(bb_nverts, nvert)
            push!(bb_times, time)
        end
        curr_ind += nvert
    end

    return (bb_simplices, bb_nverts, bb_times)
end

# Get a configuration that preserves the number of k-vertex simplices that every
# vertex participates in.
function configuration_sizes_preserved(simplices::Vector{Int64},
                                       nverts::Vector{Int64})
    config = zeros(Int64, length(simplices))
    app = copy(nverts)
    pushfirst!(app, 1)
    capp = cumsum(app)
    for val in unique(nverts)
        # Get the simplices with this number of vertices
        inds = Int64[]
        cnt = 0
        for ind in findall(nverts .== val)
            append!(inds, capp[ind]:(capp[ind] + val  - 1))
            cnt += 1
        end
        # TODO(arb): this isn't necessarily creating a simple graph
        config[inds] = shuffle(simplices[inds])
    end
    return config
end
