export PPR3, PKatz3

function full_solve(M::SpFltMat)
    K = inv(Matrix(M))
    S = copy(M)
    for j in 1:size(M, 2), i in nz_row_inds(M, j); S[i, j] = K[i, j]; end
    return S
end

function iterative_solve(M::SpFltMat, triangles::Vector{NTuple{3,Int64}})
    n = size(M, 2)
    # only compute for indices that appear in at least one triangle
    inds = zeros(Int64, n)
    for (i, j, k) in triangles; inds[[i, j, k]] .= 1; end
    shuffled_inds = shuffle(findall(inds .> 0))
    
    nthreads = Threads.nthreads()
    I = Vector{Vector{Int64}}(undef, nthreads)
    J = Vector{Vector{Int64}}(undef, nthreads)
    V = Vector{Vector{Float64}}(undef, nthreads)
    Threads.@threads for t = 1:nthreads
        I[t] = Vector{Int64}()
        J[t] = Vector{Int64}() 
        V[t] = Vector{Float64}()
    end
    Threads.@threads for ind = 1:length(shuffled_inds)
        tid = Threads.threadid()
        if tid == 1
            print(stdout, "$(ind) of $(length(shuffled_inds)) \r")
            flush(stdout)
        end
        node = shuffled_inds[ind]
        b = zeros(n)
        b[node] = 1
        sol = dqgmres(M, b, atol=1e-4, rtol=1e-4)[1]
        for i in nz_row_inds(M, node)
            push!(I[tid], i)
            push!(J[tid], node)
            push!(V[tid], sol[i])
        end
    end
    
    total = sum([length(It) for It in I])
    cI = Vector{Int64}(undef, total)
    cJ = Vector{Int64}(undef, total)
    cV = Vector{Float64}(undef, total)                
    curr_ind = 1
    for t in 1:nthreads
        size = length(I[t])
        curr_range = collect(curr_ind:(curr_ind + size - 1))
        cI[curr_range] .= I[t]
        cJ[curr_range] .= J[t]
        cV[curr_range] .= V[t]
        curr_ind += size
    end
    return sparse(cI, cJ, cV, n, n)
end

"""
PKatz3
----

Compute 3-way personalized Katz scores for triangles.

PKatz3(triangles::Vector{NTuple{3,Int64}}, B::SpIntMat,
       unweighted::Bool, dense_solve::Bool=false)

Example usage:
```
(scores, S) = PPR3(T, B, false, false)
```

Input parameters:
- triangles::Vector{NTuple{3,Int64}}: The vector of triangles upon which to compute scores.
- B::SpIntMat: Projected graph as a Sparse integer matrix, where B[i, j] is the number of times that i and j co-appear in a simplex.
- unweighted::Bool: Whether or not to use the unweighted version of the matrix.
- dense_solve::Bool=false: whether or not to use a dense solver. If B is small, then it is worth setting this option to true.

returns a tuple (scores, S):
- scores::Vector{Float64}: a vector of 3-way PPR scores for the triangles
- S::SpFltMat: a sparse matrix with the same sparsity pattern as B, where S[i, j] is the personalized Katz score of node i with respect to the seed node j.
"""
function PKatz3(triangles::Vector{NTuple{3,Int64}}, B::SpIntMat,
                unweighted::Bool, dense_solve::Bool=false)
    W = copy(B)
    if unweighted; W = make_sparse_ones(W); end
    σ_1 = svds(W,  nsv=1)[1].S[1]
    β = min(0.25 / σ_1, 0.5)
    M = I - β * W
    S = (dense_solve ? full_solve(M) : iterative_solve(M, triangles)) - I    
    scores = zeros(Float64, length(triangles))
    Threads.@threads for ind = 1:length(triangles)
        i, j, k = triangles[ind]
        scores[ind] = S[i, j] + S[j, i] + S[i, k] + S[k, i] + S[j, k] + S[k, j]
    end
    return scores, S
end

"""
PPR3
----

Compute 3-way personalized PageRank scores for triangles.

PPR3(triangles::Vector{NTuple{3,Int64}}, B::SpIntMat, 
     unweighted::Bool, dense_solve::Bool=false, α::Float64=0.85)

Example usage:
```
(scores, S) = PPR3(T, B, false, false, 0.85)
```

Input parameters:
- triangles::Vector{NTuple{3,Int64}}: The vector of triangles upon which to compute scores.
- B::SpIntMat: Projected graph as a Sparse integer matrix, where B[i, j] is the number of times that i and j co-appear in a simplex.
- unweighted::Bool: Whether or not to use the unweighted version of the matrix.
- dense_solve::Bool=false: whether or not to use a dense solver. If B is small, then it is worth setting this option to true.
- α::Float64=0.85: teleportation parameter for PageRank

returns a tuple (scores, S):
- scores::Vector{Float64}: a vector of 3-way PPR scores for the triangles
- S::SpFltMat: a sparse matrix with the same sparsity pattern as B, where S[i, j] is the personalized PageRank score of node i with respect to the seed node j.
"""
function PPR3(triangles::Vector{NTuple{3,Int64}}, B::SpIntMat,
              unweighted::Bool, dense_solve::Bool=false, α::Float64=0.85)
    W = copy(B)
    if unweighted; W = make_sparse_ones(W); end
    W = convert(SpFltMat, W)
    d = vec(sum(W, dims=1))
    nonzeros = findall(d .> 0)
    d[nonzeros] = 1.0 ./ d[nonzeros]
    M = I - α * W * Diagonal(d)
    S = (dense_solve ? full_solve(M) : iterative_solve(M, triangles)) * (1 - α)    
    scores = zeros(Float64, length(triangles))
    Threads.@threads for ind = 1:length(triangles)
        i, j, k = triangles[ind]
        scores[ind] = S[i, j] + S[j, i] + S[i, k] + S[k, i] + S[j, k] + S[k, j]
    end
    return scores, S
end
