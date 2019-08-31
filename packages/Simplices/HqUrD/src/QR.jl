"""
    QR()
Finds a vector vanishing 'gamma' such that all of its entries sum to 1.

Input arguments
---------------
gamma::Array{Float64, 2}    This matrix verifies properties necessary for QR() to work. We know that the rank of 'Gamma' n-1 (otherwise we wouldn't reach this function).
tolerance::Float64          Same as always.

Returns
-------
lambda::Vec{Float64}        A vector vanishing 'gamma'. lambda is a column vector containing the components of a vector generating Nul(M) with all the components summing up to 1.
"""
function QR(Gamma, tolerance)
   # We know that rank(Gamma)=n-1
   #and rank(Gamma0)=n
   # In addition all columns of M are non vanishing
   ## Outcome
   # lambda is a column vector containing the components of a vector generating
   # Nul(M) with all the components summing up to 1
   ##

   n = size(Gamma, 2)
   m = size(Gamma, 1) # m>=n-1
   if m == 1
      #then n<=2 but n=1 is excluded since it corresponds to a 1-vertex boundary, thus n=2 and Gamma=[a b]
      #also notice that since Gamma0=[[a b];[1 1]] has full rank it is ruled
      #out that a=b
      lambda = [Gamma[2]; -Gamma[1]] / (Gamma[2] - Gamma[1])
   else

      # M=Q*R
      #Q is an orthogonal matrix of dimension m x m
      qr_decomposition = qr(Gamma).R # access the second element of the tuple
      # R is an upper triangular matrix of dimension m x n
      R = triu(qr_decomposition)

      # diagonal is a column vector with dimension either n-1 (if m=n-1) or n (if m>=n)
      # Set entries that are too small relative to `tolerance` to zero.
      diagonal = heaviside(tolerance .- abs.(diag(R)))
      index = round.(Int, transpose(collect(1:min(m, n))) * diagonal)[1]

      if index == 0
         # the first n-1 columns are linearly independent
         index = n - 1
      else
         #the index-th entry in diag(R) is zero
         index = index - 1
      end

      lambda = zeros(n, 1)
      lambda[1:index] = - R[1:index, 1:index] \ R[1:index, index + 1] # A\b means inv(A)*b
      lambda[index + 1] = 1
      lambda = lambda / (ones(1, n) * lambda)
   end
   lambda = lambda .* heaviside(abs.(lambda) .- tolerance)

   return(lambda)
end
