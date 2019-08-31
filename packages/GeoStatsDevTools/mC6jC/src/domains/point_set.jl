# ------------------------------------------------------------------
# Licensed under the ISC License. See LICENCE in the project root.
# ------------------------------------------------------------------

"""
    PointSet(coords)

A set of points with coordinate matrix `coords`. The number of rows
of the matrix is the dimensionality of the domain whereas the number
of columns is the number of points in the set. Alternatively, `coords`
can be a vector of tuples (i.e. points).
"""
struct PointSet{T<:Real,N} <: AbstractDomain{T,N}
  coords::Matrix{T}

  function PointSet{T,N}(coords) where {N,T<:Real}
    @assert !isempty(coords) "coordinates must be non-empty"
    new(coords)
  end
end

PointSet(coords::AbstractMatrix{T}) where {T<:Real} =
  PointSet{T,size(coords,1)}(coords)

PointSet(coords::AbstractVector{NTuple{N,T}}) where {N,T<:Real} =
  PointSet([c[i] for i in 1:N, c in coords])

npoints(ps::PointSet) = size(ps.coords, 2)

function coordinates!(buff::AbstractVector{T}, ps::PointSet{T,N},
                      location::Int) where {N,T<:Real}
  for i in 1:N
    @inbounds buff[i] = ps.coords[i,location]
  end
end

# ------------
# IO methods
# ------------
function Base.show(io::IO, ps::PointSet{T,N}) where {N,T<:Real}
  dims = size(ps.coords, 1)
  npts = size(ps.coords, 2)
  print(io, "$dims×$npts PointSet{$T,$N}")
end

function Base.show(io::IO, ::MIME"text/plain", ps::PointSet{T,N}) where {N,T<:Real}
  println(io, ps)
  Base.print_array(io, ps.coords)
end
