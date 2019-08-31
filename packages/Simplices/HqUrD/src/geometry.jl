module Geometry

export centroid, squaredradius
"""
Computes the centroid of a simplex defined by vertices in 'X',
which is a matrix of dimension nx(n+1) and each column is a vertex.

Input arguments
---------------
simplex::Array{Float64, 2}  Simplex represented by an n-by-(n+1) matrix, where each column is a vertex.

Returns
-------
centroid::Array{Float64, 1}   Row vector. The centroid of the simplex.
"""
function centroid(simplex::AbstractArray{Float64, 2})
    n = size(simplex)[1]
    centroid = simplex * ones(n + 1, 1)/(n + 1)
    return(centroid)
end

"""
Computes the radius of a simplex defined by vertices in 'X',
which is a matrix of dimension nx(n+1) and each column is a vertex.

Input arguments
---------------
simplex::Array{Float64, 2}  Simplex represented by an n-by-(n+1) matrix, where each column is a vertex.

Returns
-------
radius::Float64  The radius of the simplex.

"""
function squaredradius(simplex)
    n = size(simplex)[1]
    C1 = repeat(centroid(simplex), 1, (n + 1))
    radius = maximum(ones(1, n) * ((simplex - C1)))^2
    return(radius::Float64)
end

end
