export arithmetic_mean, geometric_mean, harmonic_mean, generalized_means
export pref_attach3, common3, jaccard3, adamic_adar3
export common_nbr_set

"""
arithmetic_mean
---------------

Returns the arithmetic mean of the weights of the edges of a list of triangles.

arithmetic_mean(triangles::Vector{NTuple{3,Int64}}, B::SpIntMat)

Input parameters:
- triangles::Vector{NTuple{3,Int64}}: The vector of triangles upon which to compute scores.
- B::SpIntMat: Projected graph as a Sparse integer matrix, where B[i, j] is the number of times that i and j co-appear in a simplex.
"""
function arithmetic_mean(triangles::Vector{NTuple{3,Int64}}, B::SpIntMat)
    scores = zeros(Float64, length(triangles))
    Threads.@threads for ind = 1:length(triangles)
        i, j, k = triangles[ind]
        scores[ind] = (B[i, j] + B[j, k] + B[i, k]) / 3
    end
    return scores
end

"""
geometric_mean
---------------

Returns the geometric mean of the weights of the edges of a list of triangles.

geometric_mean(triangles::Vector{NTuple{3,Int64}}, B::SpIntMat)

Input parameters:
- triangles::Vector{NTuple{3,Int64}}: The vector of triangles upon which to compute scores.
- B::SpIntMat: Projected graph as a Sparse integer matrix, where B[i, j] is the number of times that i and j co-appear in a simplex.
"""
function geometric_mean(triangles::Vector{NTuple{3,Int64}}, B::SpIntMat)
    scores = zeros(Float64, length(triangles))
    Threads.@threads for ind = 1:length(triangles)
        i, j, k = triangles[ind]
        scores[ind] = (B[i, j] * B[j, k] * B[i, k])^(1 / 3)
    end
    return scores    
end

"""
harmonic_mean
---------------

Returns the harmonic mean of the weights of the edges of a list of triangles.

harmonic_mean(triangles::Vector{NTuple{3,Int64}}, B::SpIntMat)

Input parameters:
- triangles::Vector{NTuple{3,Int64}}: The vector of triangles upon which to compute scores.
- B::SpIntMat: Projected graph as a Sparse integer matrix, where B[i, j] is the number of times that i and j co-appear in a simplex.
"""
function harmonic_mean(triangles::Vector{NTuple{3,Int64}}, B::SpIntMat)
    scores = zeros(Float64, length(triangles))
    Threads.@threads for ind = 1:length(triangles)
        i, j, k = triangles[ind]
        scores[ind] = 3.0 / (1.0 / B[i, j] + 1.0 / B[j, k] + 1.0 / B[i, k])
    end
    return scores
end

"""
generalized_means
----------------

Computes the generalized p-means of the weights of the edges of a list of triangles.
The generalized mean of 3 values is

```math
M_p(x, y, z) = ((x^p + y^p + z^p) / 3)^{1/p}
```

generalized_means(triangles::Vector{NTuple{3,Int64}}, B::SpIntMat, ps::Float64=[-Inf; collect(-4:0.25:4); Inf])

Input parameters:
- triangles::Vector{NTuple{3,Int64}}: The vector of triangles upon which to compute scores.
- B::SpIntMat: Projected graph as a Sparse integer matrix, where B[i, j] is the number of times that i and j co-appear in a simplex.
- ps::Vector{Float64}=[-Inf; collect(-4:0.25:4); Inf]: the values of p for which to compute the means

Returns a matrix of size length(triangles) x length(ps) of the scores for the various generalized means.
"""
function generalized_means(triangles::Vector{NTuple{3,Int64}}, B::SpIntMat, ps::Vector{Float64}=[-Inf; collect(-4:0.25:4); Inf])
    scores = zeros(Float64, length(triangles), length(ps))
    Threads.@threads for ind = 1:length(triangles)
        i, j, k = triangles[ind]
        Bij, Bjk, Bik = B[i, j], B[j, k], B[i, k]
        for (r, p) in enumerate(ps)
            if     p == -Inf; scores[ind, r] = min(Bij, Bjk, Bik)
            elseif p == Inf;  scores[ind, r] = max(Bij, Bjk, Bik)
            elseif p == 0;    scores[ind, r] = (Bij * Bjk * Bik)^(1.0 / 3)
            else              scores[ind, r] = ((Bij^p + Bjk^p + Bik^p) / 3)^(1.0 / p)
            end
        end
    end
    return scores
end

"""
pref_attach3
------------

Returns the preferential attachment score for a degree vector

pref_attach3(triangles::Vector{NTuple{3,Int64}}, degrees::Vector{Int64})

The score of triangle (i, j, k) is degrees[i] * degrees[j] * degrees[k]

Input parameters:
- triangles::Vector{NTuple{3,Int64}}: The vector of triangles upon which to compute scores.
- degrees::Vector{Int64}: the degree vector
"""
function pref_attach3(triangles::Vector{NTuple{3,Int64}}, degrees::Vector{Int64})
    scores = zeros(Float64, length(triangles))
    Threads.@threads for ind = 1:length(triangles)
        i, j, k = triangles[ind]
        scores[ind] = 1.0 * degrees[i] * degrees[j] * degrees[k]
    end
    return scores    
end

""" Return common neighbors of two nodes u and v. """
function common_nbr_set(common_nbrs::NbrSetMap, u::Int64, v::Int64)
    min_node, max_node = min(u, v), max(u, v)
    if !haskey(common_nbrs, (min_node, max_node))
        return Set{Int64}()
    end
    return common_nbrs[(min_node, max_node)]
end

"""
common3
------------

Returns the number of common 4th neighbors of a list of triangles.

common3(triangles::Vector{NTuple{3,Int64}}, common_nbrs::NbrSetMap)

Input parameters:
- triangles::Vector{NTuple{3,Int64}}: The vector of triangles upon which to compute scores.
- common_nbrs::NbrSetMap: the common neighbors map attained from common_neighbors_map()
"""
function common3(triangles::Vector{NTuple{3,Int64}}, common_nbrs::NbrSetMap)
    scores = zeros(Float64, length(triangles))
    Threads.@threads for ind = 1:length(triangles)
        i, j, k = triangles[ind]
        common_ij = common_nbr_set(common_nbrs, i, j)
        common_ik = common_nbr_set(common_nbrs, i, k)
        common_jk = common_nbr_set(common_nbrs, j, k)
        common_ijk = intersect(common_ij, common_ik, common_jk)
        scores[ind] = length(common_ijk)
    end
    return scores
end

"""
jaccard3
------------

Returns the 3-way Jaccard index of the neighbor lists of nodes in triangle.

jaccard3(triangles::Vector{NTuple{3,Int64}}, common_nbrs::NbrSetMap, degrees::Vector{Int64})

Input parameters:
- triangles::Vector{NTuple{3,Int64}}: The vector of triangles upon which to compute scores.
- common_nbrs::NbrSetMap: the common neighbors map attained from common_neighbors_map()
- degrees::Vector{Int64}: degree of each node in the projected graph
"""
function jaccard3(triangles::Vector{NTuple{3,Int64}}, common_nbrs::NbrSetMap,
                  degrees::Vector{Int64})
    scores = zeros(Float64, length(triangles))
    Threads.@threads for ind = 1:length(triangles)
        i, j, k = triangles[ind]
        common_ij = common_nbr_set(common_nbrs, i, j)
        common_ik = common_nbr_set(common_nbrs, i, k)
        common_jk = common_nbr_set(common_nbrs, j, k)
        common_ijk = intersect(common_ij, common_ik, common_jk)
        nij, nik, njk = length(common_ij), length(common_ik), length(common_jk)
        nijk = length(common_ijk)
        di, dj, dk = degrees[[i, j, k]]
        scores[ind] = nijk / (di + dj + dk - nij - nik - njk + nijk)
    end
    return scores
end

"""
adamic_adar3
------------

Returns the 3-way Adamic-Adar score for a list of triangles.

adamic_adar3(triangles::Vector{NTuple{3,Int64}}, common_nbrs::NbrSetMap, degrees::Vector{Int64})

Input parameters:
- triangles::Vector{NTuple{3,Int64}}: The vector of triangles upon which to compute scores.
- common_nbrs::NbrSetMap: the common neighbors map attained from common_neighbors_map()
- degrees::Vector{Int64}: degree of each node in the projected graph
"""
function adamic_adar3(triangles::Vector{NTuple{3,Int64}}, common_nbrs::NbrSetMap,
                      degrees::Vector{Int64})
    scores = zeros(Float64, length(triangles))
    Threads.@threads for ind = 1:length(triangles)
        i, j, k = triangles[ind]
        common_ij = common_nbr_set(common_nbrs, i, j)
        common_ik = common_nbr_set(common_nbrs, i, k)
        common_jk = common_nbr_set(common_nbrs, j, k)
        common_ijk = intersect(common_ij, common_ik, common_jk)
        scores[ind] = sum([1.0 / log(degrees[z]) for z in common_ijk])
    end
    return scores
end
