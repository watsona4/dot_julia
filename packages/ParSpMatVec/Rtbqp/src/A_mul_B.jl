
export A_mul_B!

function A_mul_B!( alpha::Float64,
                   A::SparseMatrixCSC{Float64,Int},
                   x::Array{Float64},
                   beta::Float64,
                   y::Array{Float64},
                   nthreads::Int64=0 )
# Real:  y = beta*y  +  alpha * A*x 

   if nthreads == 0
      #Base.A_mul_B!( alpha, A, x, beta, y )
	  mul!(y,A,x, alpha, beta)
      return
   elseif nthreads < 1
      throw(ArgumentError("nthreads < 1"))
   end

	n,m = size(A)
    nvec = size(x,2)

   if size(x,1) != m || size(y,1) != n 
      throw(DimensionMismatch("length(x) != m || length(y) != n"))
   elseif size(y,2) != nvec
      throw(DimensionMismatch("length(y,2) != nvec"))
   end
   
   
	p  = ccall( (:a_mul_b_rr_, spmatveclib),
		 Int64, ( Ptr{Int64}, Ptr{Int64}, Ptr{Int64}, Ptr{Int64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Int64}, Ptr{Int64}, Ptr{Float64}, Ptr{Float64}),
                Ref(nthreads), Ref(nvec), Ref(m), Ref(n),    Ref(alpha),   Ref(beta),              A.nzval,      A.rowval,   A.colptr,   x,   y);
   
end  # function A_mul_B!

#------------------------------------------------------------------------------

function A_mul_B!( alpha::ComplexF64,
                   A::SparseMatrixCSC{Float64,Int},
                   x::Array{ComplexF64},
                   beta::ComplexF64,
                   y::Array{ComplexF64},
                   nthreads::Int64=0 )
# Real, Complex A:  y = beta*y  +  alpha * A*x 

   if nthreads == 0
      mul!(y,A,x, alpha, beta) # Base.A_mul_B!( alpha, complex(A), x, beta, y )
      return
   elseif nthreads < 1
      throw(ArgumentError("nthreads < 1"))
   end

	n,m  = size(A)
   nvec = size(x,2)

   if size(x,1) != m || size(y,1) != n 
      throw(DimensionMismatch("length(x) != m || length(y) != n"))
   elseif size(y,2) != nvec
      throw(DimensionMismatch("length(y,2) != nvec"))
   end
   
	p  = ccall( (:a_mul_b_rc_, spmatveclib),
		 Int64, ( Ptr{Int64}, Ptr{Int64}, Ptr{Int64}, Ptr{Int64}, Ptr{ComplexF64}, Ptr{ComplexF64}, Ptr{Float64}, Ptr{Int64}, Ptr{Int64}, Ptr{ComplexF64}, Ptr{ComplexF64}),
                   Ref(nthreads), Ref(nvec), Ref(m), Ref(n),     Ref(alpha),   Ref(beta),              A.nzval,      A.rowval,   A.colptr,   convert(Ptr{ComplexF64}, pointer(x)),  convert(Ptr{ComplexF64}, pointer(y)));
   
end  # function A_mul_B!

#------------------------------------------------------------------------------

function A_mul_B!( alpha::ComplexF64,
                   A::SparseMatrixCSC{ComplexF64,Int},
                   x::Array{ComplexF64},
                   beta::ComplexF64,
                   y::Array{ComplexF64},
                   nthreads::Int64=0 )
# Complex A:  y = beta*y  +  alpha * A*x 

   if nthreads == 0
      mul!(y,A,x, alpha, beta) # Base.A_mul_B!( alpha, A, x, beta, y )
      return
   elseif nthreads < 1
      throw(ArgumentError("nthreads < 1"))
   end

	n,m  = size(A)
   nvec = size(x,2)

   if size(x,1) != m || size(y,1) != n 
      throw(DimensionMismatch("length(x) != m || length(y) != n"))
   elseif size(y,2) != nvec
      throw(DimensionMismatch("length(y,2) != nvec"))
   end
   
	p  = ccall( (:a_mul_b_cc_, spmatveclib),
		 Int64, ( Ptr{Int64}, Ptr{Int64}, Ptr{Int64}, Ptr{Int64}, Ptr{ComplexF64}, Ptr{ComplexF64}, Ptr{ComplexF64}, Ptr{Int64}, Ptr{Int64}, Ptr{ComplexF64}, Ptr{ComplexF64}),
                   Ref(nthreads), Ref(nvec), Ref(m), Ref(n),     Ref(alpha),   Ref(beta),              convert(Ptr{ComplexF64}, pointer(A.nzval)),      A.rowval,   A.colptr,   convert(Ptr{ComplexF64}, pointer(x)),  convert(Ptr{ComplexF64}, pointer(y)));
   
end  # function A_mul_B!
