"""
  function rxdetect(X::Matrix{T}, alpha::Float64 = 0.99)

Takes data in the form of matrix where first index correspond to realisations and
second to feratures (marginals).
Using the RX (Reed-Xiaoli) Anomaly Detection returns the array of Bool that
correspond to outlier realisations. alpha is the sensitivity parameter of the RX detector

```jldoctest
julia> srand(42);

julia> x = vcat(rand(8,2), 20*rand(2,2))
10×2 Array{Float64,2}:
  0.533183    0.956916
  0.454029    0.584284
  0.0176868   0.937466
  0.172933    0.160006
  0.958926    0.422956
  0.973566    0.602298
  0.30387     0.363458
  0.176909    0.383491
 11.8582      5.25618
 14.9036     10.059

julia> rxdetect(x, 0.95)
10-element Array{Bool,1}:
 false
 false
 false
 false
 false
 false
 false
 false
  true
  true
```
"""
function rxdetect(X::Matrix{T}, alpha::Float64 = 0.99) where T <: AbstractFloat
  t = size(X,1)
  outliers = fill(false, t)
  mu = mean(X,dims=1)[1,:]
  Kinv = inv(cov(X))
  d = Chisq(size(X,2))
  for i in 1:t
    if (X[i,:] - mu)'*Kinv*(X[i,:] - mu) > quantile(d, alpha)
      outliers[i] = true
    end
  end
  outliers
end

"""
hosvdstep(X::Matrix{T}, ls::Vector{Bool}, β::Float64, r::Int, cc::SymmetricTensor{T,4}) where T <: AbstractFloat

Returns Vector{Bool} - outliers form an itteration step of th hosvd algorithm
and Vector{Float64} vector of univariate kurtosis for data projected on specific
directions
"""
function hosvdstep(X::Matrix{T}, ls::Vector{Bool}, β::Float64, r::Int, cc::SymmetricTensor{T,4}) where T <: AbstractFloat
  bestls = copy(ls)
  M = unfoldsym(cc)
  W = eigvecs(M)[:,end:-1:end-r+1]
  Z = X*W
  mm = [mad(Z[ls,i]; center=median(Z[ls,i]), normalize=true) for i in 1:r]
  me = [median(Z[ls,i]) for i in 1:r]
  for i in findall(ls)
    if maximum(abs.(Z[i,:].-me)./mm) .> β
     bestls[i] = false
   end
 end
 bestls, norm([kurtosis(Z[bestls,i]) for i in 1:r])
end

"""
  function hosvdc4detect(X::Matrix{T}, β::Float64 = 4.1, r::Int = 3; b::Int = 4)

Takes data in the form of matrix where first index correspond to realisations and
second to feratures (marginals).
Using the HOSVD of the 4'th cumulant's tensor of data returns the array of Bool that
correspond to outlier realisations. β is the sensitivity parameter while r a
number of specific directions, data are projected onto. Parameter b is a size of
blocks in a SymmetricTensors structure

```jldoctest
julia> srand(42);

julia> x = vcat(rand(8,2), 20*rand(2,2))
10×2 Array{Float64,2}:
  0.533183    0.956916
  0.454029    0.584284
  0.0176868   0.937466
  0.172933    0.160006
  0.958926    0.422956
  0.973566    0.602298
  0.30387     0.363458
  0.176909    0.383491
 11.8582      5.25618
 14.9036     10.059

julia> rxdetect(x, 0.95)
10-element Array{Bool,1}:
 false
 false
 false
 false
 false
 false
 false
 false
  true
  true
```
"""
function hosvdc4detect(X::Matrix{T}, β::Float64 = 4.1, r::Int = 3; b::Int = 4) where T <: AbstractFloat
  X = X.-mean(X,dims=1)
  s = cov(X)
  X = X*Real.(sqrt(inv(s)))
  ls = fill(true, size(X,1))
  lsold = copy(ls)
  aold = 1000000000.
  ma = momentarray(X, 4, b)
  t = size(X,1)
  while count(ls) > div(size(X,1)+r+1, 2)
    ma, t = updatemoments(ma, t, X, ls, lsold)
    lsold = copy(ls)
    c = copy(ma)
    moms2cums!(c)
    ls, a = hosvdstep(X, lsold, β, r, c[4])
    if (aold-a)/a < 0.0001
      return .!lsold
    end
    aold = a
  end
  .!lsold
end

"""
 updatemoments(ma::Vector{SymmetricTensor{Float64,N} where N}, t::Int, X::Matix{T}, ls::Vector{Bool}, lsold::Vector{Bool})

Returns Array{SymmetricTensor} - an array of updated moments (after outliers removal)
 and t - number of realisations of data after outliers removal
"""
function updatemoments(ma::Vector{SymmetricTensor{Float64,N} where N}, t::Int, X::Matrix{T}, ls::Vector{Bool}, lsold::Vector{Bool}) where T <: AbstractFloat
  lstemp = (lsold.+ls) .== 1
  if true in lstemp
    dt = count(lstemp)
    ma = t/(t-dt).*ma .- dt/(t-dt).*momentarray(X[lstemp,:], 4, ma[1].bls)
    t = t - dt
  end
  ma, t
end
