## Kalman filter for univariate linear Gaussian models

struct KalmanOut
  predictionMeans::Vector{Float64}
  predictionVariances::Vector{Float64}
  filteringMeans::Vector{Float64}
  filteringVariances::Vector{Float64}
  smoothingMeans::Vector{Float64}
  smoothingVariances::Vector{Float64}
  logZhats::Vector{Float64}
end

function lognormpdf(y::Float64, μ::Float64, σ²::Float64)
  v::Float64 = y-μ
  lnc::Float64 = -0.5*log(2*π*σ²)
  return lnc - 1/(2*σ²)*v*v
end

function kalman(theta::LGTheta, ys::Vector{Float64})
  n = length(ys)
  A = theta.A
  C = theta.C
  Q = theta.Q
  R = theta.R
  x0 = theta.x0
  v0 = theta.v0
  predictionMeans = Vector{Float64}(undef, n)
  predictionVariances = Vector{Float64}(undef, n)
  filteringMeans = Vector{Float64}(undef, n)
  filteringVariances = Vector{Float64}(undef, n)
  logZhats = Vector{Float64}(undef, n)
  mutt1 = 0.0
  mutt = 0.0
  sigmatt1 = 0.0
  sigmatt = 0.0
  lZ = 0.0
  for p = 1:n
    if p == 1
      mutt1 = x0
      sigmatt1 = v0
    else
      mutt1 = A*mutt
      sigmatt1 = A*sigmatt*A + Q
    end
    predictionMeans[p] = mutt1
    predictionVariances[p] = sigmatt1
    lZ += lognormpdf(ys[p], C*mutt1, C*sigmatt1*C + R)
    logZhats[p] = lZ
    K = sigmatt1 * C / (C * sigmatt1 * C + R)
    mutt = mutt1 + K * (ys[p]-C*mutt1)
    sigmatt = sigmatt1 - K * C * sigmatt1
    filteringMeans[p] = mutt
    filteringVariances[p] = sigmatt
  end
  smoothingMeans = Vector{Float64}(undef, n)
  smoothingVariances = Vector{Float64}(undef, n)
  smoothingMeans[n] = filteringMeans[n]
  smoothingVariances[n] = filteringVariances[n]
  for p = n:-1:2
    J = filteringVariances[p-1] * A * inv(predictionVariances[p])
    smoothingMeans[p-1] = filteringMeans[p-1] +
      J * (smoothingMeans[p] - predictionMeans[p])
    smoothingVariances[p-1] = filteringVariances[p-1] +
      J * (smoothingVariances[p] - predictionVariances[p]) * J
  end
  return KalmanOut(predictionMeans, predictionVariances, filteringMeans,
        filteringVariances, smoothingMeans, smoothingVariances, logZhats)
end

function kalmanlogZ(theta::LGTheta, ys::Vector{Float64})
  n = length(ys)
  A = theta.A
  C = theta.C
  Q = theta.Q
  R = theta.R
  x0 = theta.x0
  v0 = theta.v0
  mutt1 = 0.0
  mutt = 0.0
  sigmatt1 = 0.0
  sigmatt = 0.0
  lZ = 0.0
  for p = 1:n
    if p == 1
      mutt1 = x0
      sigmatt1 = v0
    else
      mutt1 = A*mutt
      sigmatt1 = A*sigmatt*A + Q
    end
    lZ += lognormpdf(ys[p], C*mutt1, C*sigmatt1*C + R)
    K = sigmatt1 * C / (C * sigmatt1 * C + R)
    mutt = mutt1 + K * (ys[p]-C*mutt1)
    sigmatt = sigmatt1 - K * C * sigmatt1
  end
  return lZ
end
