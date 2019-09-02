# This file is part of Kpax3. License is MIT.

abstract type State end

mutable struct AminoAcidState <: State
  R::Vector{Int}
  C::Matrix{UInt8}

  emptycluster::BitArray{1}
  cl::Vector{Int}
  k::Int

  v::Vector{Int}
  n1s::Matrix{Float64}
  unit::Vector{Vector{Int}}

  logpR::Float64
  logpC::Vector{Float64}
  loglik::Float64
  logpp::Float64
end

function AminoAcidState(data::Matrix{UInt8},
                        partition::Vector{Int},
                        priorR::PriorRowPartition,
                        priorC::AminoAcidPriorCol,
                        settings::KSettings)
  (m, n) = size(data)

  R = normalizepartition(partition, n)
  k = maximum(R)

  maxclust = min(n, max(k, settings.maxclust))

  C = zeros(UInt8, maxclust, m)

  emptycluster = trues(maxclust)
  cl = zeros(Int, maxclust)

  v = zeros(Int, maxclust)
  n1s = zeros(Float64, maxclust, m)
  unit = Vector{Int}[zeros(Int, settings.maxunit) for g in 1:maxclust]

  g = 0
  for a in 1:n
    g = R[a]

    if emptycluster[g]
      emptycluster[g] = false
    end

    if v[g] == length(unit[g])
      resize!(unit[g], min(n, v[g] + settings.maxunit))
    end

    v[g] += 1
    unit[g][v[g]] = a

    for b in 1:m
      n1s[g, b] += float(data[b, a])
    end
  end

  # we do it here and not in the previous loop because we want them sorted
  # it is not really necessary but they will be sorted during the simulation
  # anyway (we will loop on emptycluster from now on)
  i = 1
  for a in 1:length(emptycluster)
    if !emptycluster[a]
      cl[i] = a
      i += 1
    end
  end

  logpR = logdPriorRow(n, k, v, priorR)

  logpC = zeros(Float64, 2)
  computelocalmode!(v, n1s, C, cl, k, logpC, priorC)

  loglik = loglikelihood(C, cl, k, v, n1s, priorC)

  logpp = logpR + logpC[1] + loglik

  AminoAcidState(R, C, emptycluster, cl, k, v, n1s, unit, logpR, logpC, loglik,
                 logpp)
end

function copystate(x::AminoAcidState)
  R = copy(x.R)
  C = copy(x.C)

  emptycluster = copy(x.emptycluster)
  cl = copy(x.cl)
  k = x.k
  v = copy(x.v)
  n1s = copy(x.n1s)

  unit = Array{Vector{Int}}(undef, length(x.unit))
  for l in 1:length(x.unit)
    unit[l] = copy(x.unit[l])
  end

  logpR = x.logpR
  logpC = copy(x.logpC)
  loglik = x.loglik
  logpp = x.logpp

  AminoAcidState(R, C, emptycluster, cl, k, v, n1s, unit, logpR, logpC, loglik,
                 logpp)
end

function copystate!(dest::AminoAcidState,
                    src::AminoAcidState)
  resizestate!(dest, src.cl[src.k])

  if length(dest.R) == length(src.R)
    copyto!(dest.R, src.R)
  else
    dest.R = copy(src.R)
  end

  if size(dest.C, 2) != size(src.C, 2)
    dest.C = zeros(UInt8, size(dest.C, 1), size(src.C, 2))
    dest.n1s = zeros(Float64, size(dest.n1s, 1), size(src.n1s, 2))
  end

  fill!(dest.emptycluster, true)

  g = 0
  for l in 1:src.k
    g = src.cl[l]

    dest.C[g, 1] = src.C[g, 1]
    dest.emptycluster[g] = false
    dest.cl[l] = src.cl[l]
    dest.v[g] = src.v[g]
    dest.n1s[g, 1] = src.n1s[g, 1]

    if length(dest.unit[g]) < src.v[g]
      resize!(dest.unit[g], src.v[g])
    end

    copyto!(dest.unit[g], 1, src.unit[g], 1, src.v[g])
  end

  for b in 2:size(dest.C, 2)
    for l in 1:src.k
      g = src.cl[l]

      dest.C[g, b] = src.C[g, b]
      dest.n1s[g, b] = src.n1s[g, b]
    end
  end

  dest.k = src.k

  dest.logpR = src.logpR

  dest.logpC[1] = src.logpC[1]
  dest.logpC[2] = src.logpC[2]

  dest.loglik = src.loglik

  dest.logpp = src.logpp

  nothing
end

function initializestate(data::Matrix{UInt8},
                         D::Matrix{Float64},
                         kset::UnitRange{Int},
                         priorR::PriorRowPartition,
                         priorC::PriorColPartition,
                         settings::KSettings)
  n = size(data, 2)

  R = ones(Int, n)

  s = AminoAcidState(data, R, priorR, priorC, settings)

  t1 = copystate(s)
  t2 = copystate(s)

  # TODO: remove the hack once kmedoids is fixed

  if settings.verbose
    Printf.@printf("Log-posterior (plus a constant) for one cluster: %.4f.\n",
                   s.logpp)
    Printf.@printf("Now scanning %d to %d clusters.\n", kset[1], kset[end])
  end

  niter = 0
  for k in kset
    if settings.verbose && (k % 10 == 0)
      Printf.@printf("Total number of clusters = %d.\n", k)
    end

    fill!(R, 0)
    try
      copyto!(R, Clustering.kmedoids(D, k).assignments)
    catch
      StatsBase.sample!(1:k, R, replace=true)
      R[StatsBase.sample(1:n, k, replace=false)] = collect(1:k)
    end

    updatestate!(t1, data, R, priorR, priorC, settings)

    niter = 0
    while niter < 10
      try
        copyto!(R, Clustering.kmedoids(D, k).assignments)
      catch
        StatsBase.sample!(1:k, R, replace=true)
        R[StatsBase.sample(1:n, k, replace=false)] = collect(1:k)
      end

      updatestate!(t2, data, R, priorR, priorC, settings)

      if t2.logpp > t1.logpp
        copystate!(t1, t2)
      end

      niter += 1
    end

    if t1.logpp > s.logpp
      copystate!(s, t1)

      if settings.verbose
        Printf.@printf("Found a better solution! ")
        Printf.@printf("Log-posterior (plus a constant) for %d clusters: %.4f.\n",
                       k, s.logpp)
      end
    end
  end

  s
end

function updatestate!(state::AminoAcidState,
                      data::Matrix{UInt8},
                      R::Vector{Int},
                      priorR::PriorRowPartition,
                      priorC::AminoAcidPriorCol,
                      settings::KSettings)
  (m, n) = size(data)

  copyto!(state.R, normalizepartition(R, n))
  k = maximum(state.R)

  resizestate!(state, k, settings)

  state.k = k

  fill!(state.emptycluster, true)
  fill!(state.v, 0)
  fill!(state.n1s, 0.0)

  g = 0
  for a in 1:n
    g = state.R[a]

    if state.emptycluster[g]
      state.emptycluster[g] = false
    end

    if state.v[g] == length(state.unit[g])
      resize!(state.unit[g], min(n, state.v[g] + settings.maxunit))
    end

    state.v[g] += 1
    state.unit[g][state.v[g]] = a

    for b in 1:m
      state.n1s[g, b] += float(data[b, a])
    end
  end

  i = 1
  for a in 1:length(state.emptycluster)
    if !state.emptycluster[a]
      state.cl[i] = a
      i += 1
    end
  end

  state.logpR = logdPriorRow(n, state.k, state.v, priorR)

  computelocalmode!(state.v, state.n1s, state.C, state.cl, state.k,
                    state.logpC, priorC)

  state.loglik = loglikelihood(state.C, state.cl, state.k, state.v, state.n1s,
                               priorC)

  state.logpp = state.logpR + state.logpC[1] + state.loglik

  nothing
end

function resizestate!(state::AminoAcidState,
                      k::Int,
                      settings::KSettings)
  oldlen = size(state.C, 1)

  if oldlen < k
    m = size(state.C, 2)
    n = length(state.R)

    # we don't want to allocate new resources too often, so allocate double the
    # previous size. this should guarantee a logarithmic number of allocations
    newlen = min(n, max(k, 2 * oldlen))

    resize!(state.emptycluster, newlen)
    resize!(state.cl, newlen)
    resize!(state.v, newlen)
    resize!(state.unit, newlen)

    for l in (oldlen + 1):newlen
      state.emptycluster[l] = true
      state.cl[l] = 0
      state.v[l] = 0
      state.unit[l] = zeros(Int, settings.maxunit)
    end

    C = zeros(UInt8, newlen, m)
    n1s = zeros(Float64, newlen, m)

    for b in 1:m
      for l in 1:state.k
        g = state.cl[l]
        C[g, b] = state.C[g, b]
        n1s[g, b] = state.n1s[g, b]
      end
    end

    state.C = C
    state.n1s = n1s
  end

  nothing
end

function resizestate!(state::AminoAcidState,
                      k::Int)
  oldlen = size(state.C, 1)

  if oldlen < k
    m = size(state.C, 2)
    n = length(state.R)

    # we don't want to allocate new resources too often, so allocate double the
    # previous size. this should guarantee a logarithmic number of allocations
    newlen = min(n, max(k, 2 * oldlen))

    resize!(state.emptycluster, newlen)
    resize!(state.cl, newlen)
    resize!(state.v, newlen)
    resize!(state.unit, newlen)

    for l in (oldlen + 1):newlen
      state.emptycluster[l] = true
      state.cl[l] = 0
      state.v[l] = 0
      state.unit[l] = zeros(Int, 1)
    end

    C = zeros(UInt8, newlen, m)
    n1s = zeros(Float64, newlen, m)

    for b in 1:m
      for l in 1:state.k
        g = state.cl[l]
        C[g, b] = state.C[g, b]
        n1s[g, b] = state.n1s[g, b]
      end
    end

    state.C = C
    state.n1s = n1s
  end

  nothing
end

function optimumstate(x::AminoAcidData,
                      partition::String,
                      settings::KSettings)
  R = normalizepartition(partition, x.id)

  priorR = EwensPitman(settings.α, settings.θ)
  priorC = AminoAcidPriorCol(x.data, settings.γ, settings.r)

  AminoAcidState(x.data, R, priorR, priorC, settings)
end
