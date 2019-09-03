#
# element-wise check
#
function issamematrix(A::AbstractArray{T,2},B::AbstractArray{T,2}) where T
   if size(A)!=size(B)
      throw(DimensionMismatch())
   end
   (m,n) = size(A)
   for j=1:n
      for i=1:m
         if A[i,j]!=B[i,j]
            println(i," ",j," ",A[i,j]," ",B[i,j])
            return false
         end
      end
   end
   return true
end
function issamematrix(A::AbstractArray{T,2},B::AbstractArray{T,1}) where T
   if length(A)!=length(B)
      throw(DimensionMismatch())
   end
   (m,n) = size(A)
   k = 0
   for j=1:n
      for i=1:m
         k = k + 1
         if A[i,j]!=B[k]
            return false
         end
      end
   end
   return true
end
issamematrix(a::Number,b::Number) = (a==b)

#
# test matrix generation
#
function make_test_matrix(Tx, Tm, m::Int, n::Int, r::Real)
   if Tx<:SparseMatrixCSC
      return sprand(Tm,m,n,r)
   else
      return Matrix{Tm}(sprand(Tm,m,n,r))
   end
end

# convert the test matrix to dictionary
function convert_test_to_dict(M, Ti)
   Tv = eltype(M)
   if Ti <: Integer
      A = SparseMatrixDict{Tv,Ti}(M)
   else
      A = SparseMatrixDict{Tv}(M)
   end
end

# different numbers
function generate_range(IDXt, lb::Integer, ub::Integer)
   n = ub-lb+1
   if IDXt<:Number
      return rand(lb:ub),1
   elseif IDXt<:AbstractRange
      lower = max(1,rand(lb:div(n,2)))
      upper = max(1,rand(div(n,2):ub))
      steps = max(1,rand(1:div(n,4)))
      return lower:steps:upper,length(lower:steps:upper)
   elseif IDXt<:Array
      m = rand(1:n)
      return rand(lb:ub,m),m
   elseif IDXt<:Bool
      return rand(Bool,n),n
   else
      return Colon(),n
   end
end

# my findnz
function myfindnz(A)
   return (begin; I=findall(!iszero,A); (getindex.(I, 1), getindex.(I, 2), A[I]); end)
end
