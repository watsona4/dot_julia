"""
  dataupdat(X::Matrix{T}, Xplus::Matrix{T}) where T<:AbstractFloat

Returns Matrix{Float} of size(X), first u = size(Xup, 1) rows of X are removed and
at the end the updat Xplus is appended.


```jldocstests

julia> a = ones(4,4);

julia> b = zeros(2,4);

julia> dataupdat(a,b)
4×4 Array{Float64,2}:
 1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0
 0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0

```
"""
dataupdat(X::Matrix{T}, Xplus::Matrix{T}) where T<:AbstractFloat =
  vcat(X,Xplus)[1+size(Xplus, 1):end, :]


"""

    momentupdat(M::SymmetricTensor{Float, N}, X::Matrix, Xplus::Matrix)

Returns SymmetricTensor{Float, N} updated moment, given original moment, original data and update
of data - dataup

```jldocstests
julia> x = ones(6, 2);

julia> m = moment(x, 3);

julia> y = 2*ones(2,2);

julia> momentupdat(m, x, y)
SymmetricTensors.SymmetricTensor{Float64,3}(Union{Array{Float64,3}, Void}[[3.33333 3.33333; 3.33333 3.33333]
[3.33333 3.33333; 3.33333 3.33333]], 2, 1, 2, true)

```
"""
function momentupdat(M::SymmetricTensor{T, d}, X::Matrix{T}, Xplus::Matrix{T}) where {T<:AbstractFloat, d}
  tup = size(Xplus,1)
  if tup == 0
    return M
  else
    return M + tup/size(X, 1)*(moment(Xplus, d, M.bls) - moment(X[1:tup,:], d, M.bls))
  end
end

"""

  momentupdat(M::Vector{SymmetricTensor{T}}, X::Matrix{T}, Xplus::Matrix{T})

  Returns Vector{SymmetricTensor} of updated moments

"""
momentupdat(M::Vector{SymmetricTensor{T}}, X::Matrix{T}, Xplus::Matrix{T}) where T <: AbstractFloat =
    [momentupdat(M[i], X, Xplus) for i in 1:length(M)]


"""
  momentarray(X::Matrix{Float}, m::Int, b::Int)

Returns an array of Symmetric Tensors of moments given data and maximum moment order - d
"""
momentarray(X::Matrix{T}, d::Int = 4, b::Int = 4) where T <: AbstractFloat =
    [moment(X, i, b) for i in 1:d]

"""

  moms2cums!(M::Vector{SymmetricTensor})

Changes vector of Symmetric Tensors of moments to vector of Symmetric Tensors of cumulants
```jldocstests

julia> m = momentarray(ones(20,3), 3);

julia> moms2cums!(m)

julia> m[3]

SymmetricTensors.SymmetricTensor{Float64,3}(Union{Array{Float64,3}, Void}[[0.0 0.0; 0.0 0.0]
[0.0 0.0; 0.0 0.0] #undef; #undef #undef]
```

"""
function moms2cums!(M::Vector{SymmetricTensor{T}}) where T <: AbstractFloat
  d = length(M)
  for i in 1:d
    f(σ::Int) = outerprodcum(i, σ, M...; exclpartlen = 0)
    prods = pmap(f, [(2:d)...])
    for k in 2:d
      @inbounds M[i] -= prods[k-1]
    end
  end
end

"""

  cums2moms(cum::Vector{SymmetricTensor})

Returns vector of Symmetric Tensors of moments given vector of Symmetric Tensors
of cumulants
"""
function cums2moms(cum::Vector{SymmetricTensor{T}}) where T <: AbstractFloat
  m = length(cum)
  Mvec = Array{SymmetricTensor{T}}(undef, m)
  for i in 1:m
    f(σ::Int) = outerprodcum(i, σ, cum...; exclpartlen = 0)
    @inbounds Mvec[i] = cum[i]
    prods = pmap(f, [(2:m)...])
    for k in 2:m
      @inbounds Mvec[i] += prods[k-1]
    end
  end
  Mvec
end

"""
  mutable struct DataMoments{T <: AbstractFloat}

structure that stores data (X), array of moments (M) and parameters:
d - maximal moment order
b - a size of a block
"""
mutable struct DataMoments{T <: AbstractFloat}
    X::Matrix{T}
    d::Int
    b::Int
    M::Vector{SymmetricTensor{T}}
end

"""
  DataMoments(X, d, b)

a constructor, claculates an Array of moments given data and parameters
"""
DataMoments(X::Matrix{T}, d::Int, b::Int) where T <: AbstractFloat =
  DataMoments(X, d, b, momentarray(X, d, b))

"""
  function cumulantsupdate!(dm::DataMoments{T}, Xplus::Matrix{T}) where T <: AbstractFloat

updates the DataMoments structure in a sliding window, given an updat Xplus
and returns cumululants of updated data.

```jldocstests

julia> x = ones(10,2);

julia> s = DataMoments(x, 4, 2);

julia> y = zeros(4,2);

julia> cumulantsupdate!(s,y)[4]
SymmetricTensors{Float64,4}(Union{Array{Float64,4}, Void}[[0.0064 0.0064; 0.0064 0.0064]

[0.0064 0.0064; 0.0064 0.0064]

[0.0064 0.0064; 0.0064 0.0064]

[0.0064 0.0064; 0.0064 0.0064]], 2, 1, 2, true)

```
"""
function cumulantsupdate!(dm::DataMoments{T}, Xplus::Matrix{T}) where T <: AbstractFloat
  Mup = momentupdat(dm.M, dm.X, Xplus)
  Xup = dataupdat(dm.X, Xplus)
  dm.M = Mup
  dm.X = Xup
  c = copy(Mup)
  moms2cums!(c)
  c
end

"""
  savedm(dm::DataMoments, str::String)

saves a DataMoment structure at a given direcory
"""
savedm(dm::DataMoments, dir::String) = save(dir, Dict("dm" => dm))

"""
  loaddm(str::String)

loads a DataMoment structure from a given direcory
"""
loaddm(dir::String) = load(dir)["dm"]
