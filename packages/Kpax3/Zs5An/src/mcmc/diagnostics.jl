# This file is part of Kpax3. License is MIT.

function traceR(fileroot::String;
                maxlag::Int=50)
  fpR = open(string(fileroot, "_row_partition.bin"), "r")

  tmp = zeros(Int, 1)

  read!(fpR, tmp)
  n = tmp[1]

  read!(fpR, tmp)
  read!(fpR, tmp)
  N = tmp[1]

  if N - maxlag < 20
    close(fpR)
    throw(KDomainError(string("Not enough samples to estimate ",
                              "autocorrelation. Increase chain length or ",
                              "reduce value of 'maxlag'.")))
  end

  # at any given point we store maxlag + 1 partitions
  kset = zeros(Int, maxlag + 1)
  pset = zeros(Int, n, maxlag + 1)

  # read partitions into these variables
  k = zeros(Int, 1)
  R = zeros(Int, n)
  p = zeros(Int, n)
  v = zeros(Int, n)

  # output
  nl = zeros(Float64, maxlag)
  avgd = zeros(Float64, maxlag)
  entropy = fill(log(n), N)

  T = 1
  t = 1
  s = 1
  l = 1
  z = 0.0

  # the first maxlag + 1 behaves differently
  while !eof(fpR) && T <= maxlag
    read!(fpR, k)
    read!(fpR, R)

    copyto!(p, normalizepartition(R, n))

    fill!(v, 0.0)
    for i in 1:n
      v[p[i]] += 1
    end

    # compute (Shannon) partition entropy: -sum((v / n) * log(v / n))
    z = 0.0
    for g in 1:k[1]
      z += v[g] * log(v[g])
    end
    entropy[T] -= z / n

    kset[t] = k[1]
    copyto!(pset, 1 + n * (t - 1), p, 1, n)

    # compute all the lags starting from this point going backward
    l = 1
    s = t - l
    while s > 0
      nl[l] += 1
      avgd[l] += (jaccard(pset[:, t], kset[t],
                          pset[:, s], kset[s], n) - avgd[l]) / nl[l]
      l += 1
      s -= 1
    end

    t = (t <= maxlag) ? t + 1 : 1
    T += 1
  end

  while !eof(fpR)
    read!(fpR, k)
    read!(fpR, R)

    copyto!(p, normalizepartition(R, n))

    fill!(v, 0.0)
    for i in 1:n
      v[p[i]] += 1
    end

    # compute (Shannon) partition entropy: -sum((v / n) * log(v / n))
    z = 0.0
    for g in 1:k[1]
      z += v[g] * log(v[g])
    end
    entropy[T] -= z / n

    kset[t] = k[1]
    copyto!(pset, 1 + n * (t - 1), p, 1, n)

    # compute all the lags starting from this point going backward
    l = 1
    s = t - l
    while s > 0
      nl[l] += 1
      avgd[l] += (jaccard(pset[:, t], kset[t],
                          pset[:, s], kset[s], n) - avgd[l]) / nl[l]
      l += 1
      s -= 1
    end

    s = maxlag + 1
    while s > t
      nl[l] += 1
      avgd[l] += (jaccard(pset[:, t], kset[t],
                          pset[:, s], kset[s], n) - avgd[l]) / nl[l]
      l += 1
      s -= 1
    end

    t = (t <= maxlag) ? t + 1 : 1
    T += 1
  end

  close(fpR)

  if T != N + 1
    warn(string("Expecting ", N, " simulations but instead found ", T-1, "."))
  end

  (entropy, avgd)
end

function traceC(fileroot::String;
                maxlag::Int=50)
  fpC = open(string(fileroot, "_col_partition.bin"), "r")

  tmp = zeros(Int, 1)

  read!(fpC, tmp)
  n = tmp[1]

  read!(fpC, tmp)
  m = tmp[1]

  read!(fpC, tmp)
  N = tmp[1]

  if N - maxlag < 20
    close(fpC)
    throw(KDomainError(string("Not enough samples to estimate ",
                              "autocorrelation. Increase chain length or ",
                              "reduce value of 'maxlag'.")))
  end

  # at any given point we store maxlag + 1 variables
  cset = zeros(UInt8, m, maxlag + 1)

  # read column classification into these variable
  C = zeros(UInt8, m)

  # output
  avgd = zeros(Float64, maxlag)
  entropy = fill(log(m), N)

  # temporary variables
  ct = zeros(Float64, 3)
  nl = zeros(Float64, maxlag)

  T = 1
  t = 1
  s = 1
  l = 1

  # the first maxlag + 1 behaves differently
  while !eof(fpC) && T <= maxlag
    readbytes!(fpC, C, m)

    # compute (Shannon) entropy of C: -sum((ct / m) * log(ct / m))
    fill!(ct, 0.0)
    for b in 1:m
      ct[C[b]] += 1
    end

    if ct[1] > 0.0
      ct[1] *= log(ct[1])
    end

    if ct[2] > 0.0
      ct[2] *= log(ct[2])
    end

    if ct[3] > 0.0
      ct[3] *= log(ct[3])
    end

    entropy[T] -= (ct[1] + ct[2] + ct[3]) / m

    copyto!(cset, 1 + m * (t - 1), C, 1, m)

    # compute all the lags starting from this point going backward
    l = 1
    s = t - l
    while s > 0
      nl[l] += 1
      avgd[l] += (Distances.hamming(cset[:, t], cset[:, s]) / m -
                  avgd[l]) / nl[l]
      l += 1
      s -= 1
    end

    t = (t <= maxlag) ? t + 1 : 1
    T += 1
  end

  while !eof(fpC)
    readbytes!(fpC, C, m)

    # compute entropy of C: -sum((ct / m) * log(ct / m))
    fill!(ct, 0.0)
    for b in 1:m
      ct[C[b]] += 1
    end

    if ct[1] > 0.0
      ct[1] *= log(ct[1])
    end

    if ct[2] > 0.0
      ct[2] *= log(ct[2])
    end

    if ct[3] > 0.0
      ct[3] *= log(ct[3])
    end

    entropy[T] -= (ct[1] + ct[2] + ct[3]) / m

    copyto!(cset, 1 + m * (t - 1), C, 1, m)

    # compute all the lags starting from this point going backward
    l = 1
    s = t - l
    while s > 0
      nl[l] += 1
      avgd[l] += (Distances.hamming(cset[:, t], cset[:, s]) / m -
                  avgd[l]) / nl[l]
      l += 1
      s -= 1
    end

    s = maxlag + 1
    while s > t
      nl[l] += 1
      avgd[l] += (Distances.hamming(cset[:, t], cset[:, s]) / m -
                  avgd[l]) / nl[l]
      l += 1
      s -= 1
    end

    t = (t <= maxlag) ? t + 1 : 1
    T += 1
  end

  close(fpC)

  if T != N + 1
    warn(string("Expecting ", N, " simulations but instead found ", T-1, "."))
  end

  (entropy, avgd)
end

# Initial monotone sequence estimator (IMSE) of Monte Carlo variance
# Geyer C. J. (1992) Practical Markov Chain Monte Carlo.
# Statistical Science, 7 (4), pp 473-483
function imsevar(ac::Vector{Float64},
                 nsim::Int)
  if length(ac) < 2
    throw(KInputError("'maxlag' value is less than 1."))
  end

  u = div(length(ac) - 2, 2)

  s = ac[1] + ac[2]
  old = s
  cur = 0.0
  counter = 0
  for m in 1:u
    counter += 1
    cur = ac[2 * m + 1] + ac[2 * m + 2]

    if cur <= 0.0
      break
    end

    s += (cur <= old) ? cur : old
    old = cur
  end

  if counter == u
    @warn string("'maxlag' value of ", length(ac) - 1, " might not be enough ",
                 "for estimating MCMC variance. Try increasing its value.")
  end

  (-ac[1] + 2 * s) / nsim
end

function ess(variid::Float64,
             varmcmc::Float64,
             nsim::Int)
  floor(Int, nsim * variid / varmcmc)
end
