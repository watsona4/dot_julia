using SparseMatrixDicts
using Test
using SparseArrays


# Local functions:
#   issamematrix, make_test_matrix, convert_test_to_dict
#   generate_range
include("functions.jl")

# two sypes of indices
@testset "Tuple and Vector Index" begin
   m = 7
   n = 5
   A = SparseMatrixDict(m,n)
   B = SparseMatrixDict(m,n)
   M = zeros(Float64,m,n)
   for j=1:n
      for i=1:m
         val = (10.0*n)*i+j
         A[(i,j)] = val
         B[i,j] = val
         M[i,j] = val
      end
   end
   @test nnz(A)==length( myfindnz(Matrix(M))[1] )
   @test nnz(A)==nnz(B)
   for key in collect(keys(A.dict))
      @test B[key]==A[key]
   end
end

# allowance of different types
@testset "Copy and Conversion   " begin
   # to/from dense/sparse matrix
   m = 25
   n = 20
   r = 0.5
   ntests = 10
   for Tx in (Matrix,SparseMatrixCSC)
      for Tv in (Float64,Float32,Float16,Int64,Int32,Int16,Int8,Int)
         for Ti in (Int64,Int32,Int16,Int8,Int,Any)
            for round=1:ntests
               # conversion
               M = make_test_matrix(Tx,Tv,m,n,r)
               A = convert_test_to_dict(M,Ti)
               @test eltype(M)==eltype(A.dict.vals)
               @test issamematrix(A,M)
               M = Matrix{Tv}(A)
               @test eltype(M)==eltype(A.dict.vals)
               @test issamematrix(A,M)
               # copy
               B = copy(A)
               @test eltype(B.dict.vals)==eltype(A.dict.vals)
               @test eltype(B.dict.keys[1])==eltype(A.dict.keys[1])
               @test issamematrix(A,B)
            end
         end
      end
   end
end


# getindex
@testset "GetIndex              " begin
   m = 17
   n = 14
   r = 0.5
   ntests = 20
   Tx = Matrix
   for Tv in (Float64,Float32,Float16,Int64,Int32,Int16,Int8,Int)
      for Ti in (Int64,Int32,Int16,Int8,Int,Any)
         # conversion
         M = make_test_matrix(Tx,Tv,m,n,r)
         A = convert_test_to_dict(M,Ti)
         # indices
         for IDXj in (Number,AbstractRange,Array,Bool,Colon)
            for IDXi in (Number,AbstractRange,Array,Bool,Colon)
               for round=1:ntests
                  J,lenJ = generate_range(IDXj, 1, n)
                  I,lenI = generate_range(IDXi, 1, m)
                  X = A[I,J]
                  Y = M[I,J]
                  if lenI==1 && lenJ>1
                     Y = reshape(Y,1,length(Y))
                  elseif lenI>1 && lenJ==1
                     Y = reshape(Y,length(Y),1)
                  end
                  @test issamematrix(X,Y)
               end
            end
         end
      end
   end
end

# setindex simple
@testset "SetIndex Simple       " begin
   m = 18
   n = 21
   r = 0.1
   ntests = 20
   nchanges = 100
   Tx = Matrix
   for Tv in (Float64,Float32,Float16,Int64,Int32,Int16,Int8,Int)
      for Ti in (Int64,Int32,Int16,Int8,Int,Any)
         # conversion
         M = make_test_matrix(Tx,Tv,m,n,r)
         A = convert_test_to_dict(M,Ti)
         for round=1:ntests
            for k=1:nchanges
               i = rand(1:m)
               j = rand(1:m)
               v = rand(Tv)
               A[i,j] = A[i,j] + v
               M[i,j] = M[i,j] + v
            end
            @test issamematrix(A,M)
         end
      end
   end
end

# setindex
@testset "SetIndex              " begin
   m = 17
   n = 21
   r = 0.5
   ntests = 20
   Tx = Matrix
   for Tv in (Float64,Float32,Float16,Int64,Int32,Int16,Int8,Int)
      for Ti in (Int64,Int32,Int16,Int8,Int,Any)
         # conversion
         M = make_test_matrix(Tx,Tv,m,n,r)
         A = convert_test_to_dict(M,Ti)
         N = copy(M)
         B = copy(A)
         # indices
         for IDXj in (Number,AbstractRange,Array,Bool,Colon)
            for IDXi in (Number,AbstractRange,Array,Bool,Colon)
               for round=1:ntests
                  J,lenJ = generate_range(IDXj, 1, n)
                  I,lenI = generate_range(IDXi, 1, m)
                  if lenI==1 && lenJ==1
                     V = rand(Tv)
                  else
                     V = rand(Tv,lenI,lenJ)
                  end
                  # substitution
                  A[I,J] = V
                  if (isa(I,Integer) && isa(J,Integer))
                     # scalar
                     M[I,J] = V
                  elseif (lenI>1 && lenJ>1) || (lenI==1 && lenJ==1)
                     M[I,J] .= V
                  else
                     M[I,J] = V
                  end
                  X = A[I,J]
                  Y = M[I,J]
                  if lenI==1 && lenJ>1
                     Y = reshape(Y,1,length(Y))
                  elseif lenI>1 && lenJ==1
                     Y = reshape(Y,length(Y),1)
                  end
                  @test issamematrix(A,M)
                  @test issamematrix(X,Y)
                  # update
                  B[I,J] = B[I,J] .+ V
                  if length(size(N[I,J]))==1 && (lenI>1 || lenJ>1)
                     N[I,J] = N[I,J] + vec(V)
                  else
                     N[I,J] = N[I,J] .+ V
                  end
                  X = B[I,J]
                  Y = N[I,J]
                  if lenI==1 && lenJ>1
                     Y = reshape(Y,1,length(Y))
                  elseif lenI>1 && lenJ==1
                     Y = reshape(Y,length(Y),1)
                  end
                  @test issamematrix(B,N)
                  @test issamematrix(X,Y)
               end
            end
         end
      end
   end
end
