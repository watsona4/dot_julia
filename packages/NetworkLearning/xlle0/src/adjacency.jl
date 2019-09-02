#############
# Adjacency #
#############
abstract type AbstractAdjacency end

# Types
"""
Adjacency type where the adjacency information is represented by an `AbstractMatrix`.
"""
mutable struct MatrixAdjacency{T<:AbstractMatrix} <: AbstractAdjacency
	am::T
	function MatrixAdjacency(am::T) where T<:AbstractMatrix
		@assert issymmetric(am) "Adjacency matrix should be symmeric."
		new{T}(am)
	end
end

"""
Adjacency type where the adjacency information is represented by an `AbstractGraph`.
"""
mutable struct GraphAdjacency{T<:AbstractGraph} <: AbstractAdjacency
	ag::T
end

"""
Adjacency type where the adjacency information is represented by a .
function `f` and `data` on which the function can be applied. The result of
`f(data)` has to be either a matrix or a graph.
"""
mutable struct ComputableAdjacency{T,S} <:AbstractAdjacency
	f::T
	data::S
end

"""
Adjacency type where the adjacency information is represented by a
function `f` which can be used to calculate an adjacency matrix or graph, 
given proper data."
"""
mutable struct PartialAdjacency{T<:Function} <: AbstractAdjacency
	f::T
end

"Adjacency type indicating the lack of any adjacency information."
mutable struct EmptyAdjacency <: AbstractAdjacency end


# Constructors
"""
	adjacency([a,data])

Constructs an adjacency object. If `a` is a `AbstractMatrix`, `AbstractGraph` or 
`Tuple`, it will return usable adjacencies. If `a` is a `Function`
or `PartialAdjacency`, `data` has to be present. If both arguments are missing, 
the function returns an `EmptyAdjacency`.

# Examples
```
julia> using NetworkLearning, LightGraphs

julia> A = [0 1 0; 1 0 0; 0 0 0];

julia> Am = adjacency(A)
Matrix adjacency, 3 obs

julia> Ag = adjacency(Graph(A))
Graph adjacency, 3 obs

julia> Ac = adjacency(x->x,A)
Computable adjacency
```
"""
adjacency(a::T) where T<:AbstractAdjacency = a
adjacency(a::T, data) where T<:PartialAdjacency = adjacency(a.f(data))
adjacency(am::T) where T<:AbstractMatrix = MatrixAdjacency(am)
adjacency(ag::T) where T<:AbstractGraph = GraphAdjacency(ag)
adjacency(f::T, data::S) where {T,S} = ComputableAdjacency(f,data)
adjacency(t::Tuple{T,S}) where {T,S} = ComputableAdjacency(t[1],t[2])
adjacency(f::T) where T<:Function = PartialAdjacency(f)
adjacency(::Nothing) = EmptyAdjacency()
adjacency() = EmptyAdjacency()

	

# Show methods
Base.show(io::IO, a::MatrixAdjacency) = print(io, "Matrix adjacency, $(size(a.am,1)) obs")
Base.show(io::IO, a::GraphAdjacency) = print(io, "Graph adjacency, $(nv(a.ag)) obs")
Base.show(io::IO, a::ComputableAdjacency) = print(io, "Computable adjacency")
Base.show(io::IO, a::PartialAdjacency) = print(io, "Partial adjacency, not computable")
Base.show(io::IO, a::EmptyAdjacency) = print(io, "Empty adjacency, not computable")
Base.show(io::IO, va::T) where T<:AbstractVector{S} where S<:AbstractAdjacency = 
	print(io, "$(length(va))-element Vector{$S} ...")



# Methods that to strip the adjacency infomation (used in training of the NetworkLearner); the methods return a Partial Adjacency
"""
	strip_adjacency(a)

Function that removes adjancency information (i.e. matrix, graph or other data) from adjacency objects
and returns a `PartialAdjacency` that can be used in conjunction with the `adjacency` function
to build a new adjacency object.

# Examples
```
julia> using NetworkLearning, LightGraphs

julia> A = [0 1 0; 1 0 0; 0 0 0];

julia> Am = adjacency(A)
Matrix adjacency, 3 obs

julia> Ac = adjacency(x->x,A)
Computable adjacency

julia> Sm = strip_adjacency(Am)
Partial adjacency, not computable

julia> adjacency(Sm, A) # Sm has to be used with a matrix
Matrix adjacency, 3 obs

julia> Sc = strip_adjacency(Ac)
Partial adjacency, not computable

julia> adjacency(Sc, A) # Sc can be use with any data; calls f(A) where f = x->x
Matrix adjacency, 3 obs
```
"""
strip_adjacency(a::MatrixAdjacency{T}) where T <:AbstractMatrix = adjacency(x->T(x))
strip_adjacency(a::GraphAdjacency{T}) where T<:AbstractGraph = adjacency(x->T(x))
strip_adjacency(a::ComputableAdjacency{T,S}) where {T,S} = adjacency(a.f)
strip_adjacency(a::PartialAdjacency) = a
strip_adjacency(a::EmptyAdjacency) = PartialAdjacency(x->adjacency(x))



# Functions to strip the adjacency infomation (used in training of the NetworkLearner); the methods return a Partial Adjacency
"""
	update_adjacency!(a,f_update)

Function that updates the data of an adjacency object. `a` has to be a `MatrixAdjacency` or 
`GraphAdjacency` while `f_update` has to of the form `f_update = x->update_function!(x)`.

# Examples
julia> using NetworkLearning, LightGraphs

julia> A = [0 1 0; 1 0 0; 0 0 0];

julia> Am = adjacency(A)
Matrix adjacency, 3 obs

julia> update_function!(X,x,y) = begin
         X[x,y] += 1
         X[y,x] += 1
         return X
       end
update_function! (generic function with 2 methods)

julia> f_update(x,y) = X->update_function!(X,x,y)
f_update (generic function with 1 method)

julia> for i in 1:3
         update_adjacency!(Am, f_update(1,3)) # call function three times
       end

julia> adjacency_matrix(Am)
3×3 Array{Int64,2}:
 0  1  3
 1  0  0
 3  0  0
"""
update_adjacency!(a::MatrixAdjacency{T}, f_update) where T <:AbstractMatrix = begin
	sam = size(a.am)
	f_update(a.am) # f_update should be a closure calling an in-place modifier i.e.  x->foo!(x, args...)
	@assert size(a.am) == sam "The dimensions of the adjacency matrix cannot change."
	return a
end

update_adjacency!(a::GraphAdjacency{T}, f_update) where T<:AbstractGraph = begin
	n = nv(a.ag)
	f_update(a.ag) # f_update should be a closure calling an in-place modifier i.e.  x->foo!(x, args...)
	@assert nv(a.ag) == n "The number of vertices in the adjacency graph cannot change."
	return a
end

update_adjacency!(a::ComputableAdjacency{T,S}, f_update) where {T,S} = error("Cannot update a computable adjacency.")
update_adjacency!(a::PartialAdjacency, args...) = error("Cannot update a partial adjacency.")
update_adjacency!(a::EmptyAdjacency, args...) = error("Cannot update an empty adjacency.")



# Return an adjacency graph from Adjacency types
"""
	adjacency_graph(a)

Returns an adjacency graph computed from the adjacency information of `a`.
"""
adjacency_graph(a::MatrixAdjacency{T}) where T <:AbstractMatrix = adjacency_graph(a.am)
adjacency_graph(a::GraphAdjacency{T}) where T = adjacency_graph(a.ag)
adjacency_graph(a::ComputableAdjacency{T,S}) where {T,S} = adjacency_graph(a.f, a.data)
adjacency_graph(a::PartialAdjacency) = error("Insufficient information to obtain an adjacency graph.")
adjacency_graph(a::EmptyAdjacency) = error("Insufficient information to obtain an adjacency graph.")
adjacency_graph(am::T) where T <:AbstractMatrix = Graph(am)
adjacency_graph(am::T) where T <:AbstractMatrix{Float64} = SimpleWeightedGraph(am)
adjacency_graph(ag::T) where T <:AbstractGraph = ag
adjacency_graph(f::T, data::S) where {T,S} = adjacency_graph(f(data))



# Return an adjacency matrix from Adjacency types
"""
	adjacency_matrix(a)

Returns an adjacency matrix computed from the adjacency information of `a`.
"""
adjacency_matrix(a::MatrixAdjacency{T}) where T <:AbstractMatrix = adjacency_matrix(a.am)
adjacency_matrix(a::GraphAdjacency{T}) where T = adjacency_matrix(a.ag)
adjacency_matrix(a::ComputableAdjacency{T,S}) where {T,S} = adjacency_matrix(a.f, a.data)
adjacency_matrix(a::PartialAdjacency) = error("Insufficient information to obtain an adjacency matrix.")
adjacency_matrix(a::EmptyAdjacency) = error("Insufficient information to obtain an adjacency matrix.")
adjacency_matrix(am::T) where T <:AbstractMatrix = am
adjacency_matrix(ag::T) where T <:AbstractGraph = sparse(ag)
adjacency_matrix(ag::T) where T <:AbstractSimpleWeightedGraph = weights(ag)
adjacency_matrix(f::T, data::S) where {T,S} = adjacency_matrix(f(data))



"""
	adjacency_obs(A, r, obsdim)

Selects a range `r::UnitRange` of observations from the matrix `A`, along the dimension `obsdim::LearnBase.ObsDimension`.
"""
adjacency_obs(A::T where T<:AbstractMatrix, r::S where S<:UnitRange, ::ObsDim.Constant{2}) = view(A,:,r)
adjacency_obs(A::T where T<:AbstractMatrix, r::S where S<:UnitRange, ::ObsDim.Constant{1}) = view(A,r,:)
adjacency_obs(A::T where T<:SparseMatrixCSC, r::S where S<:UnitRange, ::ObsDim.Constant{2}) = A[:,r]
adjacency_obs(A::T where T<:SparseMatrixCSC, r::S where S<:UnitRange, ::ObsDim.Constant{1}) = A[r,:]
