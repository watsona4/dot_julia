mev(Σ::Matrix{T}, c, ls::Vector{Bool}) where T <: AbstractFloat = det(reduceband(Σ, ls))

function mormbased(Σ::Matrix{T}, c::Array{T, N}, ls::Vector{Bool}) where {T <: AbstractFloat, N}
  norm(reduceband(c, ls))/norm(reduceband(Σ, ls))^(N/2)
end

"""
  detoverdetfitfunction(a::Array{N}, b::Array{N})

computes the maximizing function det(C_n)/det(C_2)^(n/2). It assumes, that product
of singular values from HOSVD of tensor is a good approximation of hyperdeterminant
of the tensor (whatever that means).
Returns the value of the maximizin function
"""
function hosvdapprox(Σ::Matrix{T}, c::Array{T,N}, fibres::Vector{Bool} = [fill(true, size(Σ, 1))...]) where {T <: AbstractFloat, N}
  c = reduceband(c, fibres)
  Σ = reduceband(Σ, fibres)
  cunf = unfoldsym(c)
  eigc = abs.(eigvals(cunf*cunf'))
  eigΣ = abs.(eigvals(Σ*Σ'))
  sum(log.(eigc)-N/2*log.(eigΣ))/2
end

"""
  reduceband(ar::Array{N}, k::Vector{Bool})

Returns n-array without values at indices in ind
```jldoctest
julia>  reshape(collect(1.:27.),(3,3,3))
3×3×3 Array{Float64,3}:
[:, :, 1] =
 1.0  4.0  7.0
 2.0  5.0  8.0
 3.0  6.0  9.0

[:, :, 2] =
 10.0  13.0  16.0
 11.0  14.0  17.0
 12.0  15.0  18.0

[:, :, 3] =
 19.0  22.0  25.0
 20.0  23.0  26.0
 21.0  24.0  27.0

julia> reduceband(reshape(collect(1.:27.),(3,3,3)), [true, false, false])
1×1×1 Array{Float64,3}:
[:, :, 1] =
 1.0
```
TODO reimplement in blocks
"""
reduceband(ar::Array{T,N}, fibres::Vector{Bool}) where {T <: AbstractFloat, N} =
  ar[fill(fibres, N)...]


"""
  function unfoldsym{T <: Real, N}(ar::Array{T,N})

Returns a matrix of size (i, k^(N-1)) that is an unfold of symmetric array ar
"""
function unfoldsym(ar::Array{T,N}) where {T <: AbstractFloat, N}
  i = size(ar, 1)
  return reshape(ar, i, i^(N-1))
end

"""
TODO reimplement in blocks
"""
 function unfoldsym(t::SymmetricTensor{T, N}) where {T <: AbstractFloat, N}
   t = unfoldsym(Array(t))
   t*t'
 end

#greedy algorithm

"""
  greedestep(c::Vector{Array{Float}}, maxfunction::Function, ls::Vector{Bool})

Returns vector of bools that determines bands that maximise a function. True means include
a band, false exclude a band. It changes one true to false in input ls

```jldoctest
julia> a = reshape(collect(1.:9.), 3,3);

julia> b = reshape(collect(1.: 27.), 3,3,3);

julia> testf(ar,bool)= det(ar[1][bool,bool])

julia> greedestep(ar, testf, [true, true, true])
3-element Array{Bool,1}:
true
true
false
```
"""
function greedestep(Σ::Matrix{T}, c::Array{T, N}, maxfunction::Function,
                    ls::Vector{Bool}) where {T <: AbstractFloat, N}
  inds = findall(ls)
  bestval = SharedArray{T}(length(ls))
  bestval .= -Inf
  bestls = copy(ls)
  @sync @distributed for i in inds
    templs = copy(ls)
    templs[i] = false
    bestval[i] = maxfunction(Σ, c, templs)
  end
  v, i = findmax(bestval)
  bestls[i] = false
  return bestls, v, i
end

"""
  greedesearchdata(Σ::SymmetricTensor{T,2}, c::SymmetricTensor{T, N}, maxfunction::Function, k::Int)

returns array of bools that are non-outliers features
"""
function greedesearchdata(Σ::SymmetricTensor{T,2}, c::SymmetricTensor{T, N}, maxfunction::Function, k::Int) where {T <: AbstractFloat, N}
  ls =  [true for i=1:Σ.dats]
  Σ = Array(Σ)
  c = Array(c)
  result = []
  for i = 1:k
    ls, value, j = greedestep(Σ, c, maxfunction, ls)
    push!(result, (ls,value,j))
    value != -Inf || throw(AssertionError(" for k = $(k) optimisation does not work"))
  end
  result
end

"""
  function cumfsel(Σ::SymmetricTensor{T,2}, c::SymmetricTensor{T, N}, f::String, k::Int = Σ.dats) where {T <: AbstractFloat, N}

Returns an Array of tuples (ind::Array{Bool}, fval::Float64, i::Int). Given
k-th Array ind are marginals removed after k -steps as those with low N'th order
dependency, fval, the value of the target function at step k and i, a feature removed
at step k.

Uses Σ - the covariance matrix and c - the N'th cumulant tensor to measure the
N'th order dependencies between marginals.
Function f is the optimization function, ["hosvd", "norm", "mev"] are supported.

```jldoctest

julia> srand(42);

julia> x = rand(12,10);

julia> c = cumulants(x, 4);

julia> cumfsel(c[2], c[4], "hosvd")
10-element Array{Any,1}:
 (Bool[true, true, true, false, true, true, true, true, true, true], 27.2519, 4)
 (Bool[true, true, false, false, true, true, true, true, true, true], 22.6659, 3)
 (Bool[true, true, false, false, false, true, true, true, true, true], 18.1387, 5)
 (Bool[false, true, false, false, false, true, true, true, true, true], 14.4492, 1)
 (Bool[false, true, false, false, false, true, true, false, true, true], 11.2086, 8)
 (Bool[false, true, false, false, false, true, true, false, true, false], 7.84083, 10)
 (Bool[false, false, false, false, false, true, true, false, true, false], 5.15192, 2)
 (Bool[false, false, false, false, false, false, true, false, true, false], 2.56748, 6)
 (Bool[false, false, false, false, false, false, true, false, false, false], 0.30936, 9)
 (Bool[false, false, false, false, false, false, false, false, false, false], 0.0, 7)
```
"""
function cumfsel(Σ::SymmetricTensor{T,2}, c::SymmetricTensor{T, N}, f::String, k::Int = Σ.dats) where {T <: AbstractFloat, N}
  if f == "hosvd"
    return greedesearchdata(Σ, c, hosvdapprox, k)
  elseif f == "norm"
    return greedesearchdata(Σ, c, mormbased, k)
  elseif f == "mev"
    return greedesearchdata(Σ, c ,mev, k)
  end
  throw(AssertionError("$(f) not supported use hosvd, norm or mev"))
end

"""
  cumfsel(Σ::Matrix{T}, k::Int = size(Σ, 1))

cumfsel that uses as default the mev method
"""
cumfsel(Σ::SymmetricTensor{T,2}, k::Int = Σ.dats) where T <: AbstractFloat = cumfsel(Σ, SymmetricTensor(ones(2,2,2)), "mev", k)
