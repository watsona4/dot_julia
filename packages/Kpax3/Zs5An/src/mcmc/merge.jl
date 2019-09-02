# This file is part of Kpax3. License is MIT.

function merge!(ij::Vector{Int},
                neighbours::Vector{Int},
                S::Int,
                data::Matrix{UInt8},
                priorR::PriorRowPartition,
                priorC::PriorColPartition,
                settings::KSettings,
                support::MCMCSupport,
                state::AminoAcidState)
  # number of clusters after the merge
  k = state.k - 1

  initsupportmerge!(ij, k, data, priorC, support)

  hi = state.R[ij[1]]
  hj = state.R[ij[2]]

  # logarithm of the product of sequential probabilities
  lq = 0.0

  # temporary / support variables
  u = 0
  lcp = zeros(Float64, 2)
  lw = zeros(Float64, 2)
  z = 0.0
  p = 0.0

  vi = state.v[hi] + state.v[hj]
  ni = zeros(Float64, support.m)
  for b in 1:support.m
    ni[b] = state.n1s[hi, b] + state.n1s[hj, b]
  end

  # allocate the neighbours of i and j
  for l in 1:S
    u = neighbours[l]
    lcp[1] = lcp[2] = 0.0

    # compute p(x_{u} | x_{hi,1:(u-1)}) and p(x_{u} | x_{hj,1:(u-1)})
    for b in 1:support.m
      lcp[1] += computeclusteriseqprobs!(data[b, u], b, priorC, support)
      lcp[2] += computeclusterjseqprobs!(data[b, u], b, priorC, support)
    end

    lw[1] = clusterweight(support.vi, priorR)
    lw[2] = clusterweight(support.vj, priorR)

    # (w1 * p1) / (w1 * p1 + w2 * p2) = 1 / (1 + (w2 * p2) / (w1 * p1))
    # => e^(-log(1 + e^(log(w2) + log(p2) - log(w1) - log(p1))))
    z = -log1p(exp(lw[2] + lcp[2] - lw[1] - lcp[1]))
    p = exp(z)

    if state.R[u] == hi
      updateclusteri!(u, data, support)
      lq += z
    else
      updateclusterj!(u, data, support)
      lq += log1p(-p)
    end
  end

  updatelogmargliki!(ni, vi, priorC, support)

  logratiopriorrowmerge!(k, priorR, support)
  logmarglikmerge!(state.cl, state.k, hi, hj, priorC, support)

  ratio = exp(support.lograR + support.logmlikcandidate - support.logmlik + lq)

  if ratio >= 1 || ((ratio > 0) && (rand() <= ratio))
    performmerge!(hi, hj, ni, vi, priorC, settings, support, state)
  end

  nothing
end

function initsupportmerge!(ij::Vector{Int},
                           k::Int,
                           data::Matrix{UInt8},
                           priorC::AminoAcidPriorCol,
                           support::MCMCSupport)
  support.vi = 1
  support.vj = 1

  support.ui[1] = ij[1]
  support.uj[1] = ij[2]

  for b in 1:support.m
    initclusteriweights!(data[b, ij[1]], b, k, priorC, support)
    initclusterjweights!(data[b, ij[2]], b, k, priorC, support)
  end

  nothing
end

function performmerge!(hi::Int,
                       hj::Int,
                       ni::Vector{Float64},
                       vi::Int,
                       priorC::PriorColPartition,
                       settings::KSettings,
                       support::MCMCSupport,
                       state::AminoAcidState)
  for a in 1:state.v[hj]
    state.R[state.unit[hj][a]] = hi
  end

  state.emptycluster[hj] = true

  h = 0
  for a in 1:length(state.emptycluster)
    if !state.emptycluster[a]
      h += 1
      state.cl[h] = a
    end
  end

  state.k = h

  for b in 1:support.m
    state.n1s[hi, b] = ni[b]

    support.lp[1, hi, b] = support.lpi[1, b]
    support.lp[2, hi, b] = support.lpi[2, b]
    support.lp[3, hi, b] = support.lpi[3, b]
    support.lp[4, hi, b] = support.lpi[4, b]
  end

  resize!(state.unit[hi], vi)
  copyto!(state.unit[hi], state.v[hi] + 1, state.unit[hj], 1, state.v[hj])

  state.v[hi] = vi

  state.logpR += support.lograR

  support.logmlik = support.logmlikcandidate

  nothing
end
