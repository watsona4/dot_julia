import Compat.LinearAlgebra.diagm

## Kalman filter for multivariate linear Gaussian models

struct KalmanMVOut{d}
  predictionMeans::Vector{MVector{d, Float64}}
  predictionVariances::Vector{MMatrix{d, d, Float64}}
  filteringMeans::Vector{MVector{d, Float64}}
  filteringVariances::Vector{MMatrix{d, d, Float64}}
  smoothingMeans::Vector{MVector{d, Float64}}
  smoothingVariances::Vector{MMatrix{d, d, Float64}}
  logZhats::Vector{Float64}
end

function logmvnormpdf(y::StaticVector{d}, μ::StaticVector{d},
  Σ::StaticMatrix{d,d}) where d
  v::SVector{d,Float64} = y-μ
  lnc::Float64 = - 0.5 * d * log(2 * π) - 0.5 * logdet(Σ)
  return lnc - 0.5 * dot(v, Σ \ v)
end

function kalmanMV(theta::MVLGTheta, ys::Vector{SVector{d,Float64}}) where d
  n = length(ys)
  A = theta.A
  C = theta.C
  Q = theta.Q
  R = theta.R
  x0 = theta.x0
  v0 = theta.v0
  predictionMeans = Vector{MVector{d,Float64}}(undef, n)
  predictionVariances = Vector{MMatrix{d,d,Float64}}(undef, n)
  filteringMeans = Vector{MVector{d,Float64}}(undef, n)
  filteringVariances = Vector{MMatrix{d,d,Float64}}(undef, n)
  logZhats = Vector{Float64}(undef, n)
  mutt1 = MVector{d,Float64}(undef)
  mutt = MVector{d,Float64}(undef)
  sigmatt1 = MMatrix{d,d,Float64}(undef)
  sigmatt = MMatrix{d,d,Float64}(undef)
  lZ = 0.0
  for p = 1:n
    if p == 1
      mutt1 = x0
      sigmatt1 = diagm(0 => v0)
    else
      mutt1 = A * mutt
      sigmatt1 = A * sigmatt * A' + Q
    end
    predictionMeans[p] = mutt1
    predictionVariances[p] = sigmatt1
    lZ += logmvnormpdf(ys[p], C*mutt1, C*sigmatt1*C' + R)
    logZhats[p] = lZ
    K = sigmatt1 * C' * inv(C * sigmatt1 * C' + R)
    mutt = mutt1 + K * (ys[p] - C * mutt1)
    sigmatt = sigmatt1 - K * C * sigmatt1
    filteringMeans[p] = mutt
    filteringVariances[p] = sigmatt
  end
  smoothingMeans = Vector{MVector{d,Float64}}(undef, n)
  smoothingVariances = Vector{MMatrix{d,d,Float64}}(undef, n)
  smoothingMeans[n] = filteringMeans[n]
  smoothingVariances[n] = filteringVariances[n]
  for p = n:-1:2
    J = filteringVariances[p-1] * A' * inv(predictionVariances[p])
    smoothingMeans[p-1] = filteringMeans[p-1] +
      J * (smoothingMeans[p] - predictionMeans[p])
    smoothingVariances[p-1] = filteringVariances[p-1] +
      J * (smoothingVariances[p] - predictionVariances[p]) * J'
  end

  return KalmanMVOut(predictionMeans, predictionVariances, filteringMeans,
        filteringVariances, smoothingMeans, smoothingVariances, logZhats)
end
