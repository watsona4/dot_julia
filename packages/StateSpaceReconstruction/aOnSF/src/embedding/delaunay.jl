using Reexport
@reexport module Delaunay

import Simplices.Delaunay.delaunay
import ..Embeddings
using Statistics
using Distributions

"""
    DelaunayTriangulation
A Delaunay triangulation in dimension D. If `d`
is an instance of `DelaunayTriangulation`, then
`d.indices[i]` gives the D + 1 indices of the vertices
corresponding to the i-th simplex. The indices are
expressed in terms of the points it was produced
from.
"""
struct DelaunayTriangulation
    indices::AbstractArray{Int32, 2}
end


####################################
# Triangulation
####################################
"""
    delaunay(E::Embedding)

Perform a Delaunay triangulation of the points of the embedding.
"""
function delaunay(E::Embeddings.AbstractEmbedding)
    triang = delaunay(E.points)
    DelaunayTriangulation(triang)
end


function delaunay(E::Embeddings.AbstractEmbedding, noise_factor = 0.03)
    #Python expects row-major, so we need to transpose
    pts = transpose(E.points)

    @warn "Adding uniformly distributed noise to each observation equal to $noise_factor times the maximum of the standard deviations for each variables."

    # Find standard deviation along each axis
    σ = noise_factor .* std(pts, dims = 1)

    for i in 1:size(pts, 1)
        pts[i, :] .+= [rand(Uniform(-σ[d], σ[d])) for d = 1:size(pts, 2)]
    end

    triang = delaunay(pts)
    return DelaunayTriangulation(hcat(triang...,))
end



####################################
# Pretty printing.
####################################
function summarise(d::DelaunayTriangulation)
    _type = typeof(d)
    n_simplices = length(d)
    D = dimension(d)
    summary = "$_type with $n_simplices simplices\n"
    return join([summary, matstring(d.indices)], "")
end

Base.show(io::IO, r::DelaunayTriangulation) = println(io, summarise(r))


export
delaunay,
DelaunayTriangulation

end
