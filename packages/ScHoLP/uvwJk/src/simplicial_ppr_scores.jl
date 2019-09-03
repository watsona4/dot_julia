export Simplicial_PPR3_decomposed,
    Simplicial_PPR3_combined,
    SimplicialPROperator,
    grad_and_curl

function hodge_normalization(grad::SpIntMat, curl::SpIntMat,
                             edge_map::Dict{NTuple{2,Int64},Int64})
    d1 = convert(Vector{Float64}, vec(sum(abs.(grad), dims=1)))
    d2 = convert(Vector{Float64}, vec(sum(abs.(curl), dims=1)))
    for ((i, j), ind) in edge_map; d2[ind] += d1[i] + d1[j]; end
    nonzero_inds = findall(d2 .> 0)
    d2[nonzero_inds] = 1.0 ./ d2[nonzero_inds]
    return d2
end

"""
SimplicialPROperator
-------------

Construct the Simplicial PageRank Operator

SimplicialPROperator(grad::SpIntMat, curl::SpIntMat,
                     edge_map::Dict{NTuple{2,Int64},Int64}, α::Float64)

Input parameters:
- grad::SpIntMat: gradient operator (as a matrix)
- curl::SpIntMat: curl operator (as a matrix)
- edge_map::Dict{NTuple{2,Int64}, Int64}: maps an a sorted edge tuple to an index for the matrices
- α::Float64: teleportation parameter

returns simplicial PageRank operator
"""
function SimplicialPROperator(grad::SpIntMat, curl::SpIntMat,
                              edge_map::Dict{NTuple{2,Int64},Int64}, α::Float64)
    G = LinearOperator(convert(SpFltMat, grad))
    C = LinearOperator(convert(SpFltMat, curl))
    Dinv = opDiagonal(hodge_normalization(grad, curl, edge_map))
    L0 = (G * transpose(G) + transpose(C) * C) * Dinv
    β0 = 1 / α - 1
    return (β0 * opEye(size(L0, 1)) + L0)
end

"""
grad_and_curl
-------------

Construct the gradient and curl operators.

grad_and_curl(A::SpIntMat, At::SpIntMat, B::SpIntMat)

Input parameters:
- A::SpIntMat: (# nodes) x (# simplices) adjacency matrix
- At::SpIntMat: the transpose of A
- B::SpIntMat: Projected graph as a Sparse integer matrix, where B[i, j] is the number of times that i and j co-appear in a simplex.

returns tuple (grad, curl, edge_map):
- grad::SpIntMat: gradient operator (as a matrix)
- curl::SpIntMat: curl operator (as a matrix)
- edge_map::Dict{NTuple{2,Int64}, Int64}: maps an a sorted edge tuple to an index for the matrices
"""
function grad_and_curl(A::SpIntMat, At::SpIntMat, B::SpIntMat)
    # Gradient
    edge_map = Dict{NTuple{2, Int64}, Int64}()
    curr_ind = 1
    I, J, V = Int64[], Int64[], Int64[]
    nnodes = size(B, 2)
    for j in 1:nnodes, i in nz_row_inds(B, j)
        if i < j
            edge_map[(i, j)] = curr_ind
            push!(I, curr_ind, curr_ind)
            curr_ind += 1
            push!(J, i, j)
            push!(V, -1, 1)
        end
    end
    nedges = length(edge_map)
    println("$nedges edges...")
    grad = convert(SpIntMat, sparse(I, J, V, nedges, nnodes))

    # Curl
    nthreads = Threads.nthreads()
    Js = Vector{Vector{Int64}}(undef, nthreads)
    for tid in 1:nthreads
        Js[tid] = Vector{Int64}()
    end
    
    simplex_order = simplex_degree_order(At)
    triangle_order = proj_graph_degree_order(B)
    triangle_id = 1
    shuffled_inds = shuffle(collect(1:nnodes))
    Threads.@threads for ii = 1:length(shuffled_inds)
        i = shuffled_inds[ii]
        for (j, k) in neighbor_pairs(B, triangle_order, i)
            if i == j || i == k || j == k; continue; end
            if B[j, k] > 0 && triangle_closed(A, At, simplex_order, i, j, k)
                # Triangle (i, j, k)
                a, b, c = sort([i, j, k])
                ab, bc, ac = edge_map[(a, b)], edge_map[(b, c)], edge_map[(a, c)]
                push!(Js[Threads.threadid()], ab, bc, ac)
            end
        end
    end

    # combine arrays
    total = sum([length(J) for J in Js])
    cJ = Vector{Int64}(undef, total)
    curr_ind = 1
    for t in 1:nthreads
        size = length(Js[t])
        cJ[curr_ind:(curr_ind + size - 1)] = Js[t][:]
        curr_ind += size
    end
    # triangle indices increment by 1 every third element
    cI = zeros(Int64, length(cJ))
    curr_tri_id = 1
    curr_ind = 1
    while curr_ind <= length(cI)
        for _ in 1:3
            cI[curr_ind] = curr_tri_id
            curr_ind += 1
        end
        curr_tri_id += 1
    end
    ntriangles = curr_tri_id - 1
    # values are (1, 1, -1) for each triangle
    cV = ones(Int64, length(cJ))
    for j = 3:3:length(cV); cV[j] = -1; end
    curl = convert(SpIntMat, sparse(cI, cJ, cV, ntriangles, nedges))

    return (grad, curl, edge_map)
end

"""
Simplicial_PPR3_decomposed
--------------------------

Compute 3-way simplicial personalized PageRank scores for triangles, decomposed
into the harmonic, gradient, and curl components.

Simplicial_PPR3_decomposed(triangles::Vector{NTuple{3,Int64}}, A::SpIntMat, dense_solve::Bool=false, α::Float64=0.85)

Example usage:
```
(scores_comb, scores_curl, scores_grad, scores_harm, S_comb, S_curl, S_grad, S_harm, vec_edge_map) =
    Simplicial_PPR3_decomposed(T, A)
```

Input parameters:
- triangles::Vector{NTuple{3,Int64}}: The vector of triangles upon which to compute scores.
- A::SpIntMat: (# nodes) x (# simplices) adjacency matrix
- dense_solve::Bool=false: whether or not to use a dense solver. If the network is tiny, then it might be worth setting this option to true.
- α::Float64=0.85: teleportation parameter for PageRank

returns a tuple (scores_comb, scores_curl, scores_grad, scores_harm, S_comb, S_curl, S_grad, S_harm, vec_edge_map)
- scores_comb::Vector{Float64}: scores for "combined" simplicial personalized PageRank
- scores_curl::Vector{Float64}: scores for curl component
- scores_grad::Vector{Float64}: scores for gradient component
- scores_harm::Vector{Float64}: scores for harmonic component
- S_comb::SpFltMat: a sparse matrix, where S[x, y] is the combined simplicial PPR score for edge x with respect to edge y
- S_curl::SpFltMat: same as S_comb but for the curl component
- S_grad::SpFltMat: same as S_comb but for the gradient component
- S_harm::SpFltMat: same as S_comb but for the harmonic component
- vec_edge_map::Array{Int64,2}: 2 x (# edges) map of indices for S_comb, S_curl, S_grad, S_harm, such that the vec_edge_map[:, i] is the edge for ith index in the matrix
"""
function Simplicial_PPR3_decomposed(triangles::Vector{NTuple{3,Int64}},
                                    A::SpIntMat, dense_solve::Bool=false,
                                    α::Float64=0.85)
    At = convert(SpIntMat, A')
    B = A * At
    B -= Diagonal(B)
    grad, curl, edge_map = grad_and_curl(A, At, B)
    nedges = length(edge_map)

    # find all edges that appear in an open triangle
    in_open_tri = zeros(Int64, nedges)
    I, J = Int64[], Int64[]
    for (i, j, k) in triangles
        a, b, c = sort([i, j, k], alg=InsertionSort)
        ind1, ind2, ind3 = edge_map[(a, b)], edge_map[(a, c)], edge_map[(b, c)]
        in_open_tri[[ind1, ind2, ind3]] .= 1
        push!(I, ind1, ind1, ind2)
        push!(J, ind2, ind3, ind3)
    end
    S = sparse(I, J, ones(Float64, length(I)), nedges, nedges)
    S = make_sparse_ones(S + S')
    S_comb = convert(SpFltMat, S)
    S_grad = copy(S_comb)
    S_curl = copy(S_comb)
    S_harm = copy(S_comb)
    β0 = 1 / α - 1
    
    if dense_solve
        grad_adj = grad'
        curl_adj = curl'
        Dinv = hodge_normalization(grad, curl, edge_map)
        L1 = (grad * grad_adj + curl_adj * curl) * sparse(Diagonal(Dinv))
        M = Matrix(β0 * sparse(Diagonal(ones(Float64, size(L1, 1)))) + L1)
        println("edge flow solve...")
        Full_S = β0 * inv(M)
        for edge = 1:nedges, i in nz_row_inds(S, edge)
            S_comb[i, edge] = Full_S[i, edge]
        end
        # Gradient component
        println("gradient solve...")
        Sol = grad * (pinv(Matrix(grad)) * Full_S)
        for edge = 1:nedges, i in nz_row_inds(S, edge)
            S_grad[i, edge] = Sol[i, edge]
        end
        # Curl component
        println("curl solve...")
        Sol = curl_adj * (pinv(Matrix(curl_adj)) * Full_S)
        for edge = 1:nedges, i in nz_row_inds(S, edge)
            S_curl[i, edge] = Sol[i, edge]
        end
        # Harmonic component
        for edge = 1:nedges, i in nz_row_inds(S, edge)
            S_harm[i, edge] = S[i, edge] - S_grad[i, edge] - S_curl[i, edge]
        end
    else
        M = SimplicialPROperator(grad, curl, edge_map, α)
        dim = size(M, 1)
        curl_adj = curl'
        edges_in_open_tri = findall(in_open_tri .> 0)
        num_edges_in_open_tri = length(edges_in_open_tri)
        println("$num_edges_in_open_tri edges in open triangles...")
        
        Threads.@threads for ind = 1:num_edges_in_open_tri
            tid = Threads.threadid()
            if tid == 1
                print(stdout, "$ind of $num_edges_in_open_tri \r")
                flush(stdout)
            end
            edge = edges_in_open_tri[ind]
            b = zeros(Float64, dim)
            b[edge] = 1.0
            sol_comb = dqgmres(M, b, atol=1e-4, rtol=1e-4)[1] * β0
            # split into gradient, harmonic, and curl components
            sol_grad = grad * lsqr(grad, sol_comb, atol=1e-3, btol=1e-3)
            sol_curl = curl_adj * lsqr(curl_adj, sol_comb, atol=1e-3, btol=1e-3)
            sol_harm = sol_comb - sol_grad - sol_curl
            for i in nz_row_inds(S, edge)
                S_comb[i, edge] = sol_comb[i]
                S_grad[i, edge] = sol_grad[i]
                S_curl[i, edge] = sol_curl[i]
                S_harm[i, edge] = sol_harm[i]
            end
        end
    end

    ntriangles = length(triangles)
    scores_comb = zeros(Float64, ntriangles)
    scores_grad = zeros(Float64, ntriangles)
    scores_curl = zeros(Float64, ntriangles)
    scores_harm = zeros(Float64, ntriangles)
    function mat_score(X::SpFltMat, r1::Int64, r2::Int64, r3::Int64)
        s  = abs(X[r1, r2])
        s += abs(X[r2, r1])
        s += abs(X[r1, r3])
        s += abs(X[r3, r1])
        s += abs(X[r2, r3])
        s += abs(X[r3, r2])
        return s
    end
    Threads.@threads for ind = 1:ntriangles
        i, j, k = triangles[ind]
        a, b, c = sort([i, j, k], alg=InsertionSort)
        r1 = edge_map[(a, b)]
        r2 = edge_map[(a, c)]
        r3 = edge_map[(b, c)]
        scores_comb[ind] = mat_score(S_comb, r1, r2, r3)
        scores_grad[ind] = mat_score(S_grad, r1, r2, r3)
        scores_curl[ind] = mat_score(S_curl, r1, r2, r3)
        scores_harm[ind] = mat_score(S_harm, r1, r2, r3)
    end

    vec_edge_map = zeros(Int64, 2, length(edge_map))
    for ((i, j), ind) in edge_map
        vec_edge_map[1, ind] = i
        vec_edge_map[2, ind] = j        
    end

    return (scores_comb, scores_curl, scores_grad, scores_harm,
            S_comb,      S_curl,      S_grad,      S_harm,
            vec_edge_map)
end

"""
Simplicial_PPR3_combined
--------------------------

Compute the "combined" 3-way simplicial personalized PageRank scores for
triangles. This is less computationally expensive that the related function
Simplicial_PPR3_decomposed(), which decomposes the scores into the curl,
gradient, and harmonic components.

function Simplicial_PPR3_combined(triangles::Vector{NTuple{3,Int64}}, A::SpIntMat,
                                  At::SpIntMat, B::SpIntMat, α::Float64=0.85)


Example usage:
```
(scores_comb, S_comb, vec_edge_map) = Simplicial_PPR3_combined(T, A)
```

Input parameters:
- triangles::Vector{NTuple{3,Int64}}: The vector of triangles upon which to compute scores.
- A::SpIntMat: (# nodes) x (# simplices) adjacency matrix
- α::Float64=0.85: teleportation parameter for PageRank

returns a tuple (scores_comb, S_comb, vec_edge_map)
- scores_comb::Vector{Float64}: scores for "combined" simplicial personalized PageRank
- S_comb::SpFltMat: a sparse matrix, where S[x, y] is the combined simplicial PPR score for edge x with respect to edge y
- vec_edge_map::Array{Int64,2}: 2 x (# edges) map of indices for S_comb such that the vec_edge_map[:, i] is the edge for ith index in the matrix
"""
function Simplicial_PPR3_combined(triangles::Vector{NTuple{3,Int64}},
                                  A::SpIntMat, α::Float64=0.85)
    At = convert(SpIntMat, A')
    B = A * At
    B -= Diagonal(B)
    grad, curl, edge_map = grad_and_curl(A, At, B)
    nedges = length(edge_map)

    # find all edges that appear in an open triangle
    in_open_tri = zeros(Int64, nedges)
    I, J = Int64[], Int64[]
    for (i, j, k) in triangles
        a, b, c = sort([i, j, k], alg=InsertionSort)
        ind1, ind2, ind3 = edge_map[(a, b)], edge_map[(a, c)], edge_map[(b, c)]
        in_open_tri[[ind1, ind2, ind3]] .= 1
        push!(I, ind1, ind1, ind2)
        push!(J, ind2, ind3, ind3)
    end
    S = sparse(I, J, ones(Float64, length(I)), nedges, nedges)
    S = make_sparse_ones(S + S')
    S_comb = convert(SpFltMat, S)

    M = SimplicialPROperator(grad, curl, edge_map, α)
    dim = size(M, 1)
    curl_adj = curl'
    edges_in_open_tri = findall(in_open_tri .> 0)
    num_edges_in_open_tri = length(edges_in_open_tri)
    println("$num_edges_in_open_tri edges in open triangles...")

    Threads.@threads for ind = 1:num_edges_in_open_tri
        tid = Threads.threadid()
        if tid == 1
            print(stdout, "$ind of $num_edges_in_open_tri \r")
            flush(stdout)
        end
        edge = edges_in_open_tri[ind]
        b = zeros(Float64, dim)
        b[edge] = 1.0
        sol_comb = dqgmres(M, b, atol=1e-4, rtol=1e-4)[1] * (1 - α)
        for i in nz_row_inds(S, edge)
            S_comb[i, edge] = sol_comb[i]
        end
    end

    ntriangles = length(triangles)
    scores_comb = zeros(Float64, ntriangles)
    Threads.@threads for ind = 1:ntriangles
        i, j, k = triangles[ind]
        a, b, c = sort([i, j, k], alg=InsertionSort)
        r1 = edge_map[(a, b)]
        r2 = edge_map[(a, c)]
        r3 = edge_map[(b, c)]
        score  = abs(S_comb[r1, r2])
        score += abs(S_comb[r2, r1])
        score += abs(S_comb[r1, r3])
        score += abs(S_comb[r3, r1])
        score += abs(S_comb[r2, r3])
        score += abs(S_comb[r3, r2])
        scores_comb[ind] = score
    end

    vec_edge_map = zeros(Int64, 2, length(edge_map))
    for ((i, j), ind) in edge_map
        vec_edge_map[1, ind] = i
        vec_edge_map[2, ind] = j
    end

    return (scores_comb, S_comb, vec_edge_map)
end
