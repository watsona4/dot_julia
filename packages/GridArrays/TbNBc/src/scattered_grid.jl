
"A grid corresponding to an unstructured collection of points."
struct ScatteredGrid{T} <: AbstractGrid{T,1}
    points     ::  Vector{T}
    domain     ::  Domain
    ScatteredGrid(points::Vector{T}, domain=DomainSets.FullSpace{T}()) where T =
        new{T}(points, domain)
end

name(grid::ScatteredGrid) = "Scattered grid"

size(g::ScatteredGrid) = (length(g.points),)

unsafe_getindex(g::ScatteredGrid, idx) = g.points[idx]

support(g::ScatteredGrid) = g.domain
