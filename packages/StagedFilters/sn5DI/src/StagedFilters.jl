module StagedFilters

"""
Savitzky-Golay filter of window half-width M and degree
N. M is the number of points before and after to interpolate, i.e. the full
width of the window is 2M+1.
"""
abstract type AbstractStagedFilters end

struct SavitzkyGolayFilter{M,N} <: AbstractStagedFilters end
wrapL(i, n) = ifelse(1 ≤ i, i, i + n)
wrapR(i, n) = ifelse(i ≤ n, i, i - n)

"""
smooth!(filter,data, smoothed) -
apply `filter` to `data` writing result to `smoothed`.
Note that feeding `Int`s and not floats as data will result in a performance slowdown.
"""
@generated function smooth!(::Type{SavitzkyGolayFilter{M,N}}, data :: AbstractArray{T}, smoothed :: AbstractArray{S}) where {M,N,T,S}

  J = T[(i - M - 1 )^(j - 1) for i = 1:2M + 1, j = 1:N + 1]
  e₁ = [one(T); zeros(T,N)]
  C = J' \ e₁
  pre = :(for i = 1:$M end)
  main = :(for i = $(M + 1):n - $M end)
  post = :(for i = n - $(M - 1):n end)

  for loop in (pre, main, post)
      body = loop.args[2].args

      idx = loop !== pre ? :(i - $M) : :(wrapL(i - $M, n))   # Manually start the first iteration. See the "false" branch below.
      push!(body, :( x = muladd($(C[1]), data[$idx], $(zero(T))))) # Swap `muladd` instead of the additions. Note the index of 1.

      for j = reverse(1:M-1) # Because we bumped out the first iteration, we have to reduce the for loop index by one.
          idx = loop !== pre ? :(i - $j) : :(wrapL(i - $j, n))
          push!(body, :( x = muladd($(C[M + 1 - j]),data[$idx],x))) # muladd
      end

      push!(body, :( x = muladd($(C[M + 1]), data[i], x))) # muladd

      for j = 1:M
          idx = loop !== post ? :(i + $j) : :(wrapR(i + $j, n))
          push!(body, :( x = muladd($(C[M + 1 + j]), data[$idx], x))) # muladd
      end
      push!(body, :(smoothed[i] = x))
  end

 last_expr = quote
          n = length(data)
          n == length(smoothed) || throw(DimensionMismatch())
          @inbounds $pre; @inbounds @simd $main; @inbounds $post
          return smoothed
  end

  return last_expr = Base.remove_linenums!(last_expr)
end;

export SavitzkyGolayFilter, smooth!

end # module
