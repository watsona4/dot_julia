# This file is part of Kpax3. License is MIT.

mutable struct KWeight
  c::Vector{Float64}
  w::Matrix{Float64}
  z::Matrix{Float64}
end

mutable struct MCMCSupport
  m::Int
  n::Int

  u::Vector{Int}
  t::Vector{Float64}

  lp::Array{Float64, 3}
  lq::Array{Float64, 3}
  lr::Array{Float64, 3}

  vi::Int
  ni::Vector{Float64}
  ui::Vector{Int}
  wi::KWeight
  lpi::Matrix{Float64}

  vj::Int
  nj::Vector{Float64}
  uj::Vector{Int}
  wj::KWeight
  lpj::Matrix{Float64}

  tmp::Vector{Float64}

  cl::Vector{Int}
  k::Int

  lograR::Float64

  logmlik::Float64
  logmlikcandidate::Float64
end

function MCMCSupport(state::State,
                     priorC::AminoAcidPriorCol)
  n = length(state.R)
  (maxclust, m) = size(state.C)

  u = Int[a for a in 1:n]
  t = zeros(Float64, n)

  lp = zeros(Float64, 4, maxclust, m)
  lq = zeros(Float64, 4, maxclust, m)
  lr = zeros(Float64, 3, maxclust, m)

  g = 0
  for b in 1:m, l in 1:state.k
    g = state.cl[l]

    lp[1, g, b] = logmarglik(state.n1s[g, b], state.v[g], priorC.A[1, b],
                             priorC.B[1, b])
    lp[2, g, b] = logmarglik(state.n1s[g, b], state.v[g], priorC.A[2, b],
                             priorC.B[2, b])
    lp[3, g, b] = logmarglik(state.n1s[g, b], state.v[g], priorC.A[3, b],
                             priorC.B[3, b])
    lp[4, g, b] = logmarglik(state.n1s[g, b], state.v[g], priorC.A[4, b],
                             priorC.B[4, b])
  end

  vi = 0
  ni = zeros(Float64, m)
  ui = zeros(Int, n)
  wi = KWeight(zeros(Float64, m), zeros(Float64, 4, m), zeros(Float64, 4, m))

  lpi = zeros(Float64, 4, m)

  vj = 0
  nj = zeros(Float64, m)
  uj = zeros(Int, n)
  wj = KWeight(zeros(Float64, m), zeros(Float64, 4, m), zeros(Float64, 4, m))

  lpj = zeros(Float64, 4, m)

  tmp = zeros(Float64, 4)

  cl = zeros(Int, n)
  k = 0

  logmlik = logmarglikelihood(state.cl, state.k, lp, priorC)

  MCMCSupport(m, n, u, t, lp, lq, lr, vi, ni, ui, wi, lpi, vj, nj, uj, wj, lpj,
              tmp, cl, k, 0.0, logmlik, 0.0)
end

function resizesupport!(support::MCMCSupport,
                        maxclust::Int)
  if size(support.lp, 2) < maxclust
    # we don't want to allocate new resources too often, so allocate double the
    # previous size. this should guarantee a logarithmic number of allocations
    newsize = min(support.n, max(maxclust, 2 * size(support.lp, 2)))

    lp = zeros(Float64, 4, newsize, support.m)

    for b in 1:support.m, g in 1:size(support.lp, 2)
      lp[1, g, b] = support.lp[1, g, b]
      lp[2, g, b] = support.lp[2, g, b]
      lp[3, g, b] = support.lp[3, g, b]
      lp[4, g, b] = support.lp[4, g, b]
    end

    support.lp = lp
    support.lq = zeros(Float64, 4, newsize, support.m)
    support.lr = zeros(Float64, 3, newsize, support.m)
  end

  nothing
end

mutable struct KOffspring
  R::Vector{Int}
  v::Vector{Int}
end

mutable struct GASupport
  m::Int
  n::Int

  oi::KOffspring
  oj::KOffspring
end

function GASupport(m::Int,
                   n::Int)
  oi = KOffspring(zeros(Int, n), zeros(Int, n))
  oj = KOffspring(zeros(Int, n), zeros(Int, n))
  GASupport(m, n, oi, oj)
end
