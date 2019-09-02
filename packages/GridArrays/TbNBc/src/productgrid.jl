
"""
A `ProductGrid` represents the cartesian product of other grids.

`struct ProductGrid{TG,T,N} <: AbstractGrid{T,N}`

Parameters:
- TG is a tuple of (grid) types
- T is the element type of the grid
- N is the dimension of the grid layout
"""
struct ProductGrid{TG,T,N} <: AbstractGrid{T,N}
	grids	::	TG
end

# Generic functions for composite types:
elements(grid::ProductGrid) = grid.grids
element(grid::ProductGrid, j::Int) = grid.grids[j]
element(grid::ProductGrid, range::AbstractRange) = cartesianproduct(grid.grids[range]...)
iscomposite(::ProductGrid) = true

function ProductGrid(grids...)
	TG = typeof(grids)
	T1 = Tuple{map(eltype, grids)...}
	T2 = DomainSets.simplify_product_eltype(T1)
	ProductGrid{typeof(grids),T2,length(grids)}(grids)
end

size(g::ProductGrid) = map(length, g.grids)
size(g::ProductGrid, j::Int) = length(g.grids[j])

support(g::ProductGrid) = cartesianproduct(map(support, elements(g))...)
isperiodic(g::ProductGrid) = reduce(&, map(isperiodic, elements(g)))

getindex(g::ProductGrid{TG,T,N}, I::Vararg{Int,N}) where {TG,T,N} =
	convert(T, map(getindex, g.grids, I))

similargrid(grid::ProductGrid, ::Type{T}, dims...) where T = error()#ProductGrid([similargrid(g, eltype(T), dims[i]) for (i,g) in enumerate(elements(grid))]...)

# Flatten a sequence of elements that may be recursively composite
# For example: a ProductDomain of ProductDomains will yield a list of each of the
# individual domains, like the leafs of a tree structure.
function flatten(::Type{T}, elements::Array, BaseType = Any) where {T}
    flattened = BaseType[]
    for element in elements
        append_flattened!(T, flattened, element)
    end
    flattened
end

flatten(T, elements...) = tuple(flatten(T, [el for el in elements])...)

function append_flattened!(::Type{T}, flattened::Vector, element::T) where {T}
    for el in elements(element)
        append_flattened!(T, flattened, el)
    end
end

function append_flattened!(::Type{T}, flattened::Vector, element) where {T}
    append!(flattened, [element])
end



for (BaseType,TPType) in [ (:AbstractGrid, :ProductGrid)]
    # Override × for grids
    @eval cross(args::$BaseType...) = cartesianproduct(args...)
	@eval ^(arg::$BaseType, n::Int) = cartesianproduct(arg, n)
    # In order to avoid strange nested structures, we flatten the arguments
    @eval cartesianproduct(args::$BaseType...) = $TPType(flatten($TPType, args...)...)
    @eval cartesianproduct(arg::$BaseType, n::Int) = cartesianproduct([arg for i in 1:n]...)
    # Disallow cartesian products with just one argument
    @eval cartesianproduct(arg::$BaseType) = arg
end
