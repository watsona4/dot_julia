"""
	struct IndexSubGrid{G,I,T,N} <: AbstractSubGrid{T,N}

An IndexSubGrid is a subgrid corresponding to a certain range of indices of the
underlying grid.
It is assumed to be an 1D grid.
"""
struct IndexSubGrid{G,I,T,N} <: AbstractSubGrid{T,N}
	supergrid  :: G
	subindices :: I
	domain 	   :: Domain

	function IndexSubGrid{G,I,T,N}(supergrid::AbstractGrid{T,N}, subindices, domain=Interval(first(supergrid), last(supergrid))) where {G,I,T,N}
		@assert length(subindices) <= length(supergrid)
		new(supergrid, subindices, domain)
	end
end

IndexSubGrid(grid::AbstractGrid{T,N}, i, domain=Interval(first(grid), last(grid))) where {T,N} =
    IndexSubGrid{typeof(grid),typeof(i),T,N}(grid, i, domain)

name(g::IndexSubGrid) = "Index-based subgrid"

subindices(g::IndexSubGrid) = g.subindices

similar_subgrid(g::IndexSubGrid, g2::AbstractGrid) = IndexSubGrid(g2, subindices(g))

length(g::IndexSubGrid) = length(subindices(g))

size(g::IndexSubGrid) = (length(g),)

eachindex(g::IndexSubGrid) = eachindex(subindices(g))

# The speed of this routine is the main reason why supergrid and subindices
# are typed fields, leading to extra type parameters.
unsafe_getindex(g::IndexSubGrid, idx) = unsafe_getindex(g.supergrid, g.subindices[idx])

function mask(g::IndexSubGrid)
    mask = zeros(Bool,size(supergrid(g)))
    [mask[i]=true for i in g.subindices]
    mask
end


support(g::IndexSubGrid) = g.domain



# Check whether element grid[i] (of the underlying grid) is in the indexed subgrid.
issubindex(i, g::IndexSubGrid) = in(i, subindices(g))

# getindex(grid::AbstractGrid, i::Range) = IndexSubGrid(grid, i)

getindex(grid::AbstractGrid, i::AbstractArray{Int}) = IndexSubGrid(grid, i)
