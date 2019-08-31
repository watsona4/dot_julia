# Test functions for checking Stirling1 and Stirling2


"""
Common code for the two Stirling matrix functions.
"""
function _matrix_maker(n::Int, f::Function)
  if n<0
    throw(DomainError())
  end

  M = zeros(BigInt,n+1,n+1)
  for i=0:n
    for j=0:n
      M[i+1,j+1] = f(i,j)
    end
  end
  return M
end

"""
`Stirling1matrix(n)` creates an `n+1`-by-`n+1` matrix
of Stirling numbers of the first kind (from `0,0` to `n,n`).
"""
function Stirling1matrix(n::Int)
  return _matrix_maker(n,Stirling1)
end


"""
`Stirling2matrix(n)` creates an `n+1`-by-`n+1` matrix
of Stirling numbers of the second kind (from `0,0` to `n,n`).
"""
function Stirling2matrix(n::Int)
  return _matrix_maker(n,Stirling2)
end
