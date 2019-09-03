export rref, rref!, solve, solve_augmented

"""
`swap_rows!(A,i,j)` swaps rows `i` and `j` in the matrix `A`.
"""
function swap_rows!(A::Array{T,2}, i::Int, j::Int) where T
  if i==j
    return nothing
  end
  A[ [i,j], :] = A[ [j,i], :]
  return nothing
end


"""
`add_row_to_row!(A,i,j)` adds row `i` to row `j` in the matrix `A`.
"""
function add_row_to_row!(A::Array{T,2},i::Int,j::Int) where T<:Number
  A[j,:] += A[i,:]
  return nothing
end

# The following functions developed by Tara Abrishami

"""
`rref!(A)` overwrites `A` with its row reduced echelon form.
"""
function rref!(A::Array{GF2,2})
  r, c = size(A)
  s = 0
  for x in 1:r
    b = false
    while !b && x + s <= c
      if A[x, x+s] == 1
        break
      elseif A[x, x + s] == 0
        for y in x:r
          if A[y, x + s] == 1
            swap_rows!(A, y, x)
            b = true
            break
          end
        end
      end
      if !b
        s = s + 1
      end
    end
    for m in 1:r
      if x + s <= c && m != x && A[m, x+s] == 1
        add_row_to_row!(A, x, m)
      end
    end
  end
end

"""
`rref(A)` returns the row reduced echelon form of `A`.
"""
function rref(A::Array{GF2,2})
  AA = copy(A)
  rref!(AA)
  return AA
end


"""
`solve(A,b)` returns a solution `x` to the linear system
`A*x == b` or throws an error if no solution can be found.
"""
function solve(A::Array{GF2, 2}, b::Array{GF2, 1})
  r, c = size(A)
  if r != size(b)[1]
    error("Dimensionally incorrect input")
  end
  C = [A b]
  return solve_augmented(C)
end

# returns a single solution to the system with matrix C1
function solve_augmented(C1::Array{GF2, 2})
  r, c = size(C1)
  D = copy(C1)
  rref!(D)
  x = 0
  for a in 1:r
   in = true
   for b in 1:c-1
     if D[a, b] != 0
       in = false
     end
   end
   if in && D[a, c] != 0
     error("Inconsistent system")
   end
  end
  ret = zeros(GF2, c-1)
  for p in 1:r
    if D[p, c] == 1
      for n in 1:c-1
        if D[p, n] == 1
          ret[n] = 1
          break
        end
      end
    end
  end
  return ret
end



import Base.inv

function inv(A::Array{GF2,2})
  n,m = size(A)
  if n!= m
    error("Cannot invert a matrix that isn't square.")
  end
  if det(A)==0
    error("Cannot invert a singular matrix.")
  end
  In = Matrix{GF2}(I,n,n)

  AB = [A  In]
  rref!(AB)

  B = AB[:,n+1:end]
  return B
end





function LinearAlgebra.nullspace(A::Array{GF2, 2})
  r, c = size(A)
  M = rref(A)
  ret = zeros(GF2, c)
  s = 0
  x = 1
  left = false
  while x <= c
    if x > r
      left = true
      break
    end
    if x + s > c
      break
    end
    if M[x, x+s] == 1
      x = x + 1
      continue
    else
      p = zeros(GF2, c)
      p[x + s] = 1
      for t in 1:r
        if M[t, x + s] == 1
          for q in 1:c
            if M[t, q] == 1
              p[q] = 1
              break
            end
          end
        end
      end
      s = s + 1
      ret = hcat(ret, p)
    end
  end
  if left
    while x + s <= c
      p = zeros(GF2, c)
      p[x + s] = 1
      for t in 1:r
        if M[t, x + s] == 1
          for q in 1:c
            if M[t, q] == 1
              p[q] = 1
              break
            end
          end
        end
      end
      s = s + 1
      ret = hcat(ret, p)
    end
  end
  ret = ret[:, 1:size(ret,2) .!= 1]
  return ret
end

export solve_all
"""
`solve_all(A,b)` returns a solution to `A*x==b` together with
a basis for the nullspace of `A`.
"""
function solve_all(A::Array{GF2, 2}, b::Array{GF2, 1})
  return solve(A, b), nullspace(A)
end

export nullity
"""
`nullity(A)` returns the dimension of the nullspace of `A`.
"""
function nullity(A::Array{GF2,2})
  NS = nullspace(A)
  (x,n) = size(NS)
  return n
end

function LinearAlgebra.rank(A::Array{GF2,2})
  r,c = size(A)
  n = nullity(A)
  return c-n
end
