"""
	FullPairwise

A type representing an association matrix with a "saturated" parametrization--one parameter 
for each edge in the graph.

In this type, the association matrix for each observation is a symmetric matrix with the 
same pattern of nonzeros as the graph's adjacency matrix, but with arbitrary values in those
locations. The package convention is to provide parameters as a vector of `Float64`.  So 
`getparameters` and `setparameters!` use a vector of `ne(G)` values that correspond to the 
nonzero locations in the upper triangle of the adjacency matrix, in the same (lexicographic)
order as `edges(G)`.

The association matrix is stored as a `SparseMatrixCSC{Float64,Int64}` in the field Λ.

This type does not allow for different observations to have different association matricse.
So while `size` returns a 3-dimensional result, the third index is ignored
when accessing the array's elements.

# Constructors

	FullPairwise(G::SimpleGraph, count::Int=1)
	FullPairwise(n::Int, count::Int=1)
	FullPairwise(λ::Real, G::SimpleGraph)
	FullPairwise(λ::Real, G::SimpleGraph, count::Int)
	FullPairwise(λ::Vector{Float64}, G::SimpleGraph)

If provide only a graph, set λ = zeros(nv(G)).
If provide only an integer, set λ to zeros and make a totally disconnected graph.
If provide a graph and a scalar, convert the scalar to a vector of the right length.

# Examples
```jldoctest
julia> g = makegrid4(2,2).G;
julia> λ = [1.0, 2.0, -1.0, -2.0];
julia> p = FullPairwise(λ, g);
julia> typeof(p.Λ)
SparseArrays.SparseMatrixCSC{Float64,Int64}

julia> Matrix(p[:,:])
4×4 Array{Float64,2}:
 0.0   1.0   2.0   0.0
 1.0   0.0   0.0  -1.0
 2.0   0.0   0.0  -2.0
 0.0  -1.0  -2.0   0.0
```
"""
mutable struct FullPairwise <: AbstractPairwiseParameter
	λ::Vector{Float64}
	G::SimpleGraph{Int}
	count::Int
	Λ::SparseMatrixCSC{Float64,Int64}
	function FullPairwise(lam, g, m)
		if length(lam) !== ne(g)
			error("FullPairwise: length(λ) must equal the number of edges in the graph.")
		end
		if m < 1
			error("FullPairwise: count must be positive")
		end
		i = 1
		Λ = sparse(zeros(nv(g),nv(g)))
		for e in edges(g)
			Λ[e.src,e.dst] = Λ[e.dst,e.src] = lam[i]
			i += 1
		end
		new(lam, g, m, Λ)
	end
end

# Constructors
# - If provide only a graph, set λ = zeros(nv(graph)).
# - If provide only an integer, set λ to zeros and make a totally disconnected graph.
# - If provide a graph and a scalar, convert the scalar to a vector of the right length.
FullPairwise(G::SimpleGraph, count::Int=1) = FullPairwise(zeros(ne(G)), G, count)
FullPairwise(n::Int, count::Int=1) = FullPairwise(0, SimpleGraph(n), count)
FullPairwise(λ::Real, G::SimpleGraph) = FullPairwise((Float64)(λ)*ones(ne(G)), G, 1)
FullPairwise(λ::Real, G::SimpleGraph, count::Int) = FullPairwise((Float64)(λ)*ones(ne(G)), G, count)
FullPairwise(λ::Vector{Float64}, G::SimpleGraph) = FullPairwise(λ, G, 1)

#---- AbstractArray methods ---- (following sparsematrix.jl)

# getindex - implementations 
getindex(p::FullPairwise, i::Int, j::Int) = p.Λ[i, j]
getindex(p::FullPairwise, i::Int) = p.Λ[i]
getindex(p::FullPairwise, ::Colon, ::Colon) = p.Λ
getindex(p::FullPairwise, I::AbstractArray) = p.Λ[I]
getindex(p::FullPairwise, I::AbstractVector, J::AbstractVector) = p.Λ[I,J]

# getindex - translations
getindex(p::FullPairwise, I::Tuple{Integer, Integer}) = p[I[1], I[2]]
getindex(p::FullPairwise, I::Tuple{Integer, Integer, Integer}) = p[I[1], I[2]]
getindex(p::FullPairwise, i::Int, j::Int, r::Int) = p[i,j]
getindex(p::FullPairwise, ::Colon, ::Colon, ::Colon) = p[:,:]
getindex(p::FullPairwise, ::Colon, ::Colon, r::Int) = p[:,:]
getindex(p::FullPairwise, ::Colon, j) = p[1:size(p.Λ,1), j]
getindex(p::FullPairwise, i, ::Colon) = p[i, 1:size(p.Λ,2)]
getindex(p::FullPairwise, ::Colon, j, r) = p[:,j]
getindex(p::FullPairwise, i, ::Colon, r) = p[i,:]
getindex(p::FullPairwise, I::AbstractVector{Bool}, J::AbstractRange{<:Integer}) = p[findall(I),J]
getindex(p::FullPairwise, I::AbstractRange{<:Integer}, J::AbstractVector{Bool}) = p[I,findall(J)]
getindex(p::FullPairwise, I::Integer, J::AbstractVector{Bool}) = p[I,findall(J)]
getindex(p::FullPairwise, I::AbstractVector{Bool}, J::Integer) = p[findall(I),J]
getindex(p::FullPairwise, I::AbstractVector{Bool}, J::AbstractVector{Bool}) = p[findall(I),findall(J)]
getindex(p::FullPairwise, I::AbstractVector{<:Integer}, J::AbstractVector{Bool}) = p[I,findall(J)]
getindex(p::FullPairwise, I::AbstractVector{Bool}, J::AbstractVector{<:Integer}) = p[findall(I),J]

# setindex!
setindex!(p::FullPairwise, i::Int, j::Int) =
	error("Pairwise values cannot be set directly. Use setparameters! instead.")
setindex!(p::FullPairwise, i::Int, j::Int, k::Int) = 
	error("Pairwise values cannot be set directly. Use setparameters! instead.")
setindex!(p::FullPairwise, i::Int) =
	error("Pairwise values cannot be set directly. Use setparameters! instead.")


#---- AbstractPairwiseParameter interface methods ----
# For getparameters(), update p.λ before returning the parameters (to avoid case
# where Λ is manually replaced without updating the parameter vector).
# For separameters!() update Λ whenever the parameters change.
function getparameters(p::FullPairwise)
	i = 1
	for e in edges(p.G)
		p.λ[i] = p.Λ[e.src,e.dst]
		i += 1
	end
	return p.λ
end
function setparameters!(p::FullPairwise, newpar::Vector{Float64})
	i = 1
	for e in edges(p.G)
		p.λ[i] = newpar[i]
		p.Λ[e.src,e.dst] = newpar[i]
		p.Λ[e.dst,e.src] = newpar[i]
		i += 1
	end
end


#---- to be used in show methods ----
function showfields(p::FullPairwise, leadspaces=0)
    spc = repeat(" ", leadspaces)
    return spc * "λ      edge-ordered vector of association parameter values\n" *
		   spc * "G      the graph ($(nv(p.G)) vertices, $(ne(p.G)) edges)\n" *
		   spc * "count  $(p.count) (the number of observations)\n" *
		   spc * "Λ      $(size2string(p.Λ)) SparseMatrixCSC (the association matrix)\n"
end

