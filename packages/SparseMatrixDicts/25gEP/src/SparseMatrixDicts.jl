
__precompile__()

# sparse matrix with dictionary (a.k.a. hash matrix)

# The sparse dictionary matrix (smd) is assumed to be used as
# temporary storage to set up a CSC matrix. So this package
# only supports limited functions for the purpose.

# Some functions are derived from sparsematrix.jl.

module SparseMatrixDicts

import LinearAlgebra: Symmetric
import SparseArrays: AbstractSparseArray, SparseMatrixCSC,
                     nnz, nzrange, sparse, findnz

import Base: size, show, setindex!, getindex, copy, vec, transpose,
             haskey, fill, fill!, similar

export SparseMatrixDict

"""
    SparseMatrixDict{Tv,Ti<:Integer} <: AbstractSparseMatrix{Tv,Ti}
    s = SparseMatrixDict{Tv,Ti}(m,n)

Matrix type for storing sparse matrices in the
Dictionary format as Dict{Tuple{Ti,Ti},Tv}.
The constructor accepts two arguments: the number of rows (m) and
the number of columns (n).
"""
struct SparseMatrixDict{Tv,Ti<:Integer} <: AbstractSparseArray{Tv,Ti,2}
   m::Int                      # Number of rows
   n::Int                      # Number of columns
   dict::Dict{Tuple{Ti,Ti},Tv} # Stored values

   function SparseMatrixDict{Tv,Ti}(m::Integer, n::Integer) where {Tv,Ti<:Integer}
      m < 0 && throw( ArgumentError("invalid rows") )
      n < 0 && throw( ArgumentError("invalid columns") )
      new(Int(m), Int(n), Dict{Tuple{Ti,Ti},Tv}())
   end
   function SparseMatrixDict{Tv,Ti}(m::Integer, n::Integer, dict::Dict{Tuple{Ti,Ti},Tv}) where {Tv,Ti<:Integer}
      m < 0 && throw( ArgumentError("invalid rows") )
      n < 0 && throw( ArgumentError("invalid columns") )
      new(Int(m), Int(n), dict)
   end
end

@inbounds function SparseMatrixDict{Tv,Ti}(S::SparseMatrixCSC{Tv,Tj}) where {Tv,Ti<:Integer,Tj<:Integer}
   (m, n) = size(S)
   A = SparseMatrixDict{Tv,Ti}(m, n)
   for Sj in 1:S.n
      for Sk in nzrange(S, Sj)
         Si = S.rowval[Sk]
         Sv = S.nzval[Sk]
         A[Si, Sj] = Sv
      end
   end
   return A
end

@inbounds function SparseMatrixDict{Tv,Ti}(M::AbstractArray) where {Tv,Ti<:Integer}
   (m, n) = size(M)
   #(I, J, V) = findnz(M)
   (I, J, V) = (begin; I=findall(!iszero,M); (getindex.(I, 1), getindex.(I, 2), M[I]); end)
   nnz = length(I)
   A = SparseMatrixDict{Tv,eltype(I)}(m, n)
   for i=1:nnz
      A[(I[i],J[i])] = convert(Tv,V[i])
   end
   return A
end

# the default constructor
SparseMatrixDict(m::Integer, n::Integer) =
   SparseMatrixDict{Float64,Int64}(m, n)
SparseMatrixDict(S::SparseMatrixCSC{Tv,Ti}) where {Tv,Ti<:Integer} =
   SparseMatrixDict{Tv,Ti}(S)
SparseMatrixDict{Tv}(M::AbstractArray) where {Tv} =
   SparseMatrixDict{Tv,Int64}(M)
SparseMatrixDict(M::AbstractArray{Tv}) where {Tv} =
   SparseMatrixDict{Tv,Int64}(M)


# output

function show(io::IO, ::MIME"text/plain", A::SparseMatrixDict)
   xnnz = nnz(A)
   print(io, A.m, "×", A.n, " ", typeof(A), " with ", xnnz, " stored ",
         xnnz == 1 ? "entry" : "entries")
   if xnnz != 0
      print(io, ":")
      show(io, A)
   end
end

show(io::IO, A::SparseMatrixDict) = Base.show(convert(IOContext, io), A::SparseMatrixDict)
function show(io::IOContext, A::SparseMatrixDict)
   if nnz(A) == 0
      return show(io, MIME("text/plain"), A)
   end
   for key in sort(collect(keys(A.dict)))
      print(io, "\n  [", key[1], ", ", key[2], "]  =  ", A.dict[key])
   end
end

# standard functions

copy(A::SparseMatrixDict{Tv,Ti}) where {Tv,Ti<:Integer} = SparseMatrixDict{Tv,Ti}(A.m, A.n, copy(A.dict))
size(A::SparseMatrixDict{Tv,Ti}) where {Tv,Ti<:Integer} = (A.m, A.n)
nnz(A::SparseMatrixDict{Tv,Ti}) where {Tv,Ti<:Integer} = A.dict.count
haskey(A::SparseMatrixDict{Tv,Ti},idx::Tuple{Ti,Ti}) where {Tv,Ti<:Integer} = haskey(A.dict,idx)
haskey(A::SparseMatrixDict{Tv,Ti},i::Ti,j::Ti) where {Tv,Ti<:Integer} = haskey(A.dict,(i,j))
haskey(A::SparseMatrixDict{Tv,Ti},i,j) where {Tv,Ti<:Integer} = haskey(A.dict,(convert(Ti,i),convert(Ti,j)))

function vec(A::SparseMatrixDict{Tv,Ti}) where {Tv,Ti<:Integer}
   v::Vector{Tv} = zeros(Tv,A.m*A.n)
   k::Int = 0
   for j=1:A.n
      for i=1:A.m
         k = k + 1
         @inbounds v[k] = A[(i,j)]
      end
   end
   return v
end

function transpose(A::SparseMatrixDict{Tv,Ti}) where {Tv,Ti<:Integer}
   B = SparseMatrixDict{Tv,Ti}(A.n, A.m)
   for key in collect(keys(A.dict))
      @inbounds B[(key[2],key[1])] = A[key]
   end
   return B
end

function fill(v, A::SparseMatrixDict{Tv,Ti}) where {Tv,Ti<:Integer}
   B = copy(A)
   x = convert(Tv,v)
   for key in collect(keys(B.dict))
      B[key] = x
   end
   return B
end

function fill!(v, A::SparseMatrixDict{Tv,Ti}) where {Tv,Ti<:Integer}
   x = convert(Tv,v)
   for key in collect(keys(A.dict))
      A[key] = x
   end
end

similar(A::SparseMatrixDict{Tv,Ti}) where {Tv,Ti<:Integer} = fill(0.0, A)

function findnz(A::SparseMatrixDict{Tv,Ti}) where {Tv,Ti<:Integer}
   nnzA = nnz(A)
   I = zeros(Int, nnzA)
   J = zeros(Int, nnzA)
   NZs = Vector{Tv}(undef, nnzA)
   #NZs = Vector{Tv}(nnzA)
   cnt = 1
   if nnzA>1
      for (i,j) in collect(keys(A.dict))
         I[cnt] = i
         J[cnt] = j
         NZs[cnt] = A[(i,j)]
         cnt += 1
      end
   end
   return (I, J, NZs)
end

#function findnz(A::AbstractMatrix)
#   return (begin; I=findall(!iszero,A); (getindex.(I, 1), getindex.(I, 2), A[I]); end)
#end

function sparse(A::SparseMatrixDict{Tv,Ti}) where {Tv,Ti<:Integer}
   (I, J, NZs) = findnz(A)
   return sparse(I, J, NZs)
end


# setindex

function setindex!(A::SparseMatrixDict{Tv,Ti}, v, i, j) where {Tv,Ti<:Integer}
   setindex!( A, convert(Tv, v), (convert(Ti,i),convert(Ti, j)) )
end
function setindex!(A::SparseMatrixDict{Tv,Ti}, v::Tv, i::Ti, j::Ti) where {Tv,Ti<:Integer}
   setindex!( A, v, (i,j) )
end
function setindex!(A::SparseMatrixDict{Tv,Ti}, v, idx::Tuple{Any,Any}) where {Tv,Ti<:Integer}
   setindex!( A, convert(Tv, v), (convert(Ti,idx[1]),convert(Ti,idx[2])) )
end
function setindex!(A::SparseMatrixDict{Tv,Ti}, v::Tv, idx::Tuple{Ti,Ti}) where {Tv,Ti<:Integer}
   if !((1 <= idx[1] <= A.m) & (1 <= idx[2] <= A.n))
      throw(BoundsError(A, idx))
   end
   A.dict[idx] = v
end

function setindex!(A::SparseMatrixDict{Tv,Ti}, v::Number,
   I::AbstractVector{<:Integer}, J::AbstractVector{<:Integer}) where {Tv,Ti<:Integer}
   if isempty(I) || isempty(J); return A; end
   if (I[1] < 1 || I[end] > A.m) || (J[1] < 1 || J[end] > A.n)
      throw(BoundsError(A, (I, J)))
   end
   x = convert(Tv,v)
   for j=collect(J)
      for i=collect(I)
         A[(i,j)] = x
      end
   end
end

setindex!(A::SparseMatrixDict{Tv,Ti}, v::Number, I::AbstractVector{<:Integer}, j::Integer) where {Tv,Ti<:Integer} =
   setindex!(A, v, I, j:j)
setindex!(A::SparseMatrixDict{Tv,Ti}, v::Number, i::Integer, J::AbstractVector{<:Integer}) where {Tv,Ti<:Integer} =
   setindex!(A, v, i:i, J)
setindex!(A::SparseMatrixDict{Tv,Ti}, v::Number, I::AbstractVector{<:Integer}, ::Colon) where {Tv,Ti<:Integer} =
   setindex!(A, v, I, 1:size(A,2))
setindex!(A::SparseMatrixDict{Tv,Ti}, v::Number, ::Colon, J::AbstractVector{<:Integer}) where {Tv,Ti<:Integer} =
   setindex!(A, v, 1:size(A,1), J)
setindex!(A::SparseMatrixDict{Tv,Ti}, v::Number, i::Integer, ::Colon) where {Tv,Ti<:Integer} =
   setindex!(A, v, i:i, 1:size(A,2))
setindex!(A::SparseMatrixDict{Tv,Ti}, v::Number, ::Colon, j::Integer) where {Tv,Ti<:Integer} =
   setindex!(A, v, 1:size(A,1), j:j)
setindex!(A::SparseMatrixDict{Tv,Ti}, v::Number, ::Colon, ::Colon) where {Tv,Ti<:Integer} =
   setindex!(A, v, 1:size(A,1), 1:size(A,2))

function setindex!(A::SparseMatrixDict{Tv,Ti}, B::AbstractArray{Tv},
   I::AbstractVector{<:Integer}, J::AbstractVector{<:Integer}) where {Tv,Ti<:Integer}
   if (size(B,1)!=length(I) || size(B,2)!=length(J))
      throw(DimensionMismatch("Cannot do this"))
   end
   if (I[1] < 1 || I[end] > A.m) || (J[1] < 1 || J[end] > A.n)
      throw(BoundsError(A, (I, J)))
   end
   if typeof(B)<:AbstractSparseArray
      (IB, JB, NZs) = findnz(B)
      n = length(I)
      for k=1:n
         i = I[IB[k]]
         j = J[JB[k]]
         key = (i,j)
         if !haskey(A.dict,key) && iszero(NZs[k])
            # skip
         else
            A[key] = NZs[k]
         end
      end
   else
      p = length(I)
      q = length(J)
      for j=1:q
         for i=1:p
            key = (I[i],J[j])
            if !haskey(A.dict,key) && iszero(B[i,j])
               # skip
            else
               A[key] = B[i,j]
            end
         end
      end
   end
end

setindex!(A::SparseMatrixDict{Tv,Ti}, B::AbstractArray{Tv}, I::AbstractVector{<:Integer}, j::Integer) where {Tv,Ti<:Integer} =
   setindex!(A, B, I, j:j)
setindex!(A::SparseMatrixDict{Tv,Ti}, B::AbstractArray{Tv}, i::Integer, J::AbstractVector{<:Integer}) where {Tv,Ti<:Integer} =
   setindex!(A, B, i:i, J)
setindex!(A::SparseMatrixDict{Tv,Ti}, B::AbstractArray{Tv}, I::AbstractVector{<:Integer}, ::Colon) where {Tv,Ti<:Integer} =
   setindex!(A, B, I, 1:size(A,2))
setindex!(A::SparseMatrixDict{Tv,Ti}, B::AbstractArray{Tv}, ::Colon, J::AbstractVector{<:Integer}) where {Tv,Ti<:Integer} =
   setindex!(A, B, 1:size(A,1), J)
setindex!(A::SparseMatrixDict{Tv,Ti}, B::AbstractArray{Tv}, i::Integer, ::Colon) where {Tv,Ti<:Integer} =
   setindex!(A, B, i:i, 1:size(A,2))
setindex!(A::SparseMatrixDict{Tv,Ti}, B::AbstractArray{Tv}, ::Colon, j::Integer) where {Tv,Ti<:Integer} =
   setindex!(A, B, 1:size(A,1), j:j)
setindex!(A::SparseMatrixDict{Tv,Ti}, B::AbstractArray{Tv}, ::Colon, ::Colon) where {Tv,Ti<:Integer} =
   setindex!(A, B, 1:size(A,1), 1:size(A,2))

# for symmetric matrix
#
# In general, it should be avoided to put off-diagonals in a symmetric matrix
# because the result is not unique (several possible implementations there).
# Here, this function simply ignores the input if the index is out of range.
#
function setindex!(SA::Symmetric{Tv,SparseMatrixDict{Tv,Ti}}, v, i, j) where {Tv,Ti<:Integer}
   setindex!( SA, convert(Tv, v), (convert(Ti,i),convert(Ti, j)) )
end
function setindex!(SA::Symmetric{Tv,SparseMatrixDict{Tv,Ti}}, v::Tv, i::Ti, j::Ti) where {Tv,Ti<:Integer}
   setindex!( SA, v, (i,j) )
end
function setindex!(SA::Symmetric{Tv,SparseMatrixDict{Tv,Ti}}, v, idx::Tuple{Any,Any}) where {Tv,Ti<:Integer}
   setindex!( SA, convert(Tv, v), (convert(Ti,idx[1]),convert(Ti,idx[2])) )
end
function setindex!(SA::Symmetric{Tv,SparseMatrixDict{Tv,Ti}}, v::Tv, idx::Tuple{Ti,Ti}) where {Tv,Ti<:Integer}
   if SA.uplo=='U' && idx[1]<=idx[2]
      setindex!(SA.data, v, idx)
   elseif idx[1]>=idx[2]
      setindex!(SA.data, v, idx)
   end
end


# getindex

function getindex(A::SparseMatrixDict{Tv,Ti}, i, j) where {Tv,Ti<:Integer}
   return getindex( A, (convert(Ti,i),convert(Ti,j)) )
end
function getindex(A::SparseMatrixDict{Tv,Ti}, i::Ti, j::Ti) where {Tv,Ti<:Integer}
   return getindex( A, (i,j) )
end
function getindex(A::SparseMatrixDict{Tv,Ti}, idx::Tuple{Any,Any}) where {Tv,Ti<:Integer}
   return getindex( A, (convert(Ti,t[1]),convert(Ti,t[2])) )
end
function getindex(A::SparseMatrixDict{Tv,Ti}, idx::Tuple{Ti,Ti}) where {Tv,Ti<:Integer}
   if !((1 <= idx[1] <= A.m) & (1 <= idx[2] <= A.n))
      throw(BoundsError(A, idx))
   end
   if haskey(A.dict,idx)
      return A.dict[idx]
   else
      return convert(Tv,0.0)
   end
end

function getindex(A::SparseMatrixDict{Tv,Ti}, I::AbstractVector, J::AbstractVector) where {Tv,Ti<:Integer}
   (m, n) = size(A)
   if !isempty(J)
      minj, maxj = extrema(J)
      ((minj < 1) || (maxj > n)) && throw(BoundsError())
   end
   if !isempty(I)
      mini, maxi = extrema(I)
      ((mini < 1) || (maxi > m)) && throw(BoundsError())
   end
   if isempty(I) || isempty(J) || (0 == nnz(A))
      error("empty matrix")
   end
   return getindex_general(A, I, J)
end

@inbounds function getindex_general(A::SparseMatrixDict{Tv,Ti}, I::AbstractVector, J::AbstractVector) where {Tv,Ti<:Integer}
   p = length(I)
   q = length(J)
   B = SparseMatrixDict{Tv,Ti}(p,q)
   for j=1:q
      for i=1:p
         idx = (I[i],J[j])
         if haskey(A.dict,idx)
            B[(i,j)] = A[idx]
         end
      end
   end
   return B
end

getindex(A::SparseMatrixDict{Tv,Ti}, i::Integer, J::AbstractVector) where {Tv,Ti<:Integer} =
   getindex_general(A, i:i, J)
getindex(A::SparseMatrixDict{Tv,Ti}, I::AbstractVector, j::Integer) where {Tv,Ti<:Integer} =
   getindex_general(A, I, j:j)
getindex(A::SparseMatrixDict{Tv,Ti}, ::Colon, J::AbstractVector) where {Tv,Ti<:Integer} =
   getindex_general(A, 1:size(A,1), J)
getindex(A::SparseMatrixDict{Tv,Ti}, I::AbstractVector, ::Colon) where {Tv,Ti<:Integer} =
   getindex_general(A, I, 1:size(A,2))
getindex(A::SparseMatrixDict, ::Colon, ::Colon) = copy(A)
getindex(A::SparseMatrixDict, i::Integer, ::Colon) = getindex(A, i, 1:size(A,2))
getindex(A::SparseMatrixDict, ::Colon, j::Integer) = getindex(A, 1:size(A,1), j)

#getindex(A::SparseMatrixDict, I::AbstractRange{<:Integer}, J::AbstractVector{Bool}) = A[I,findall(J)]
#getindex(A::SparseMatrixDict, I::Integer, J::AbstractVector{Bool}) = A[I,findall(J)]
#getindex(A::SparseMatrixDict, I::AbstractVector{Bool}, J::Integer) = A[findall(I),J]
#getindex(A::SparseMatrixDict, I::AbstractVector{Bool}, J::AbstractVector{Bool}) = A[findall(I),findall(J)]
#getindex(A::SparseMatrixDict, I::AbstractVector{<:Integer}, J::AbstractVector{Bool}) = A[I,findall(J)]
#getindex(A::SparseMatrixDict, I::AbstractVector{Bool}, J::AbstractVector{<:Integer}) = A[findall(I),J]

#getindex(A::SparseMatrixDict, I::AbstractRange{<:Integer}, J::AbstractVector{Bool}) = A[I,find(J)]
getindex(A::SparseMatrixDict, I::Integer, J::AbstractVector{Bool}) = A[I,find(J)]
getindex(A::SparseMatrixDict, I::AbstractVector{Bool}, J::Integer) = A[find(I),J]
getindex(A::SparseMatrixDict, I::AbstractVector{Bool}, J::AbstractVector{Bool}) = A[find(I),find(J)]
getindex(A::SparseMatrixDict, I::AbstractVector{<:Integer}, J::AbstractVector{Bool}) = A[I,find(J)]
getindex(A::SparseMatrixDict, I::AbstractVector{Bool}, J::AbstractVector{<:Integer}) = A[find(I),J]


end
