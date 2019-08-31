using StaticArrays
using Simplices.delaunayn

"""
A triangulation of a cloud of embedded points into disjoint simplices.

```julia
# Triangulate a set of random points in 3D space.
t = triangulate(rand(20, 3))

# Refine triangulation until all simplices are below the mean radius of the original
# triangulation.
target_radius = mean(t.radii)
refine_variable_k!(t, target_radius)
```

"""
abstract type AbstractTriangulation{D, N} <: Partition end

"""
    Triangulation{D <:Int, N <:Int}

A triangulation type. D is the dimension of the triangulated space. N = D + 1,
which equals the number of vertices each simplex in the triangulation has.
"""
struct Triangulation{D<:Int, N <:Int} <: AbstractTriangulation{D, N}
    E::AbstractEmbedding
    d::DelaunayTriangulation
    centroids::Array{Float64, 2}
    radii::Vector{Float64}
    orientations::Vector{Float64}
    volumes::Vector{Float64}
end

radii(t::AbstractTriangulation) = t.radii[1:end-1]
centroids(t::AbstractTriangulation) = t.centroids
orientations(t::AbstractTriangulation) = t.orientations
volumes(t::AbstractTriangulation) t.volumes



export dimension, npoints, radii, volumes, orientations

"""
    LinearlyInvariantTriangulation <: Triangulation`
A triangulation for which we have made sure the point corresponding to the last time
    index falls within the convex hull of the other points.
"""
struct LinearlyInvariantTriangulation{D <:Int, N <:Int} <: AbstractTriangulation{D, N}
    points::Array{Float64, 2}
    simplex_inds::Array{Int32, 2}
end


function triangulate(E::LinearlyInvariantEmbedding)
    simplex_inds = delaunay(E)
    D = length(simplex_inds[1]) - 1; N = D + 1
    N = D + 1
    points = E.points[1:end-1, :]
    LinearlyInvariantTriangulation{D, N}(points, simplex_inds)
end

function triangulate(E::AbstractEmbedding)
    simplex_inds = delaunayn(E)
    D = length(simplex_inds[1]) - 1; N = D + 1
    points = E.points[1:end-1, :]
    Triangulation{D, N}(points, simplex_inds)
end

triangulate(pts::AbstractArray{Float64, 2}) = triangulate(embed(pts))

function Base.summary(t::AbstractTriangulation)
    npts = size(t.embedding.points, 1)
    nsimplices = size(t.simplex_inds, 1)
    dim = size(t.embedding.points, 2)
    embeddingtype_tri = typeof(t)
    embeddingtype_emb = typeof(t.embedding)
    return """$dim-dimensional $(embeddingtype_tri) with $nsimplices simplices constructed
            from a $npts-pt $embeddingtype_emb"""
end

function matstring(t::AbstractTriangulation)
    fields = fieldnames(t)
    fields_str = String.(fields)
    maxlength = maximum([length(str) for str in fields_str]) + 2
    fields_str = [fields_str[i] *
                repeat(" ", maxlength - length(fields_str[i])) for i = 1:length(fields_str)]

    summaries = [join(":"*String(fields_str[i])*summary(getfield(t, fields[i]))*"\n") for i = 1:length(fields_str)] |> join
    infoline = "The following fields are available:\n"

    return summary(t)#*"\n\n"*infoline*summaries
end

Base.show(io::IO, t::AbstractTriangulation) = println(io, matstring(t))

"""
Find the indices of the simplices in the original triangulation that potentially
intersect with the image simplex with index `image_i`.
"""
function maybeintersecting_simplices(t::AbstractTriangulation, image_i::Int)
    inds_potential_simplices = Int[]

    n_simplices = length(t.radii)

    @inbounds for i = 1:n_simplices
        dist_difference = (transpose(t.centroids_im[image_i] - t.centroids[i]) *
                            (t.centroids_im[image_i] - t.centroids[i]) -
                                (t.radii_im[image_i] + t.radii[i])^2)[1]
        if dist_difference < 0
            push!(inds_potential_simplices, i)
        end
    end
    return inds_potential_simplices
end


"""
Find the indices of the image simplices in `t` that potentially intersect with
the original simplex with index `orig_i`.
"""
function maybeintersecting_imsimplices(t::AbstractTriangulation, orig_i::Int)
    inds_potential_simplices = Int[]

    n_simplices = length(t.radii)

    @inbounds for i = 1:n_simplices
        dist_difference = (transpose(t.centroids[orig_i] - t.centroids_im[i]) *
                            (t.centroids[orig_i] - t.centroids_im[i]) -
                                (t.radii[orig_i] + t.radii_im[i])^2)[1]
        if dist_difference < 0
            push!(inds_potential_simplices, i)
        end
    end
    return inds_potential_simplices
end


"""
Draw point representatives from the simplices of a triangulation `t`.

Precedure:
1) Generate one point per simplex.
2) Points are generated from the interior or on the boundary of each simplex.
3) Points are drawn according to a uniform distribution.
"""
function point_representatives(t::AbstractTriangulation)
    dim = size(t.points, 2)
    n_simplices = size(t.simplex_inds, 1)

    # Pre-allocate array to hold the points
    point_representatives = zeros(Float64, n_simplices, dim)

    # Loop over the rows of the simplex_inds array to access all the simplices.
    for i = 1:n_simplices
        simplex = t.points[t.simplex_inds[i], :]
        point_representatives[i, :] = Delaunay.childpoint(simplex)
    end

    return point_representatives
end
