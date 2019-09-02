# This file is part of Kpax3. License is MIT.

function biased_random_walk!(data::Matrix{UInt8},
                             priorR::PriorRowPartition,
                             priorC::PriorColPartition,
                             settings::KSettings,
                             support::MCMCSupport,
                             state::AminoAcidState)
  k = state.k

  i = StatsBase.sample(1:support.n)
  hi = state.R[i]
  hj = 0

  v = 0
  if state.v[hi] > 1
    if k > 1
      v = StatsBase.sample(1:k)

      if v == k
        # move i to a new cluster
        k += 1
      end
    else
      # move i to a new cluster
      k = 2
    end
  else
    # move i to another cluster
    k -= 1
    v = StatsBase.sample(1:k)
  end

  if k == state.k
    hj = state.cl[v] < hi ? state.cl[v] : state.cl[v + 1]

    initsupportbrwmove!(i, hi, hj, data, support, state)

    support.lograR = logratiopriorrowmove(state.v[hi], state.v[hj], priorR)

    updatelogmargliki!(priorC, support)
    updatelogmarglikj!(priorC, support)

    logmarglikbrwmove!(state.cl, state.k, hi, hj, priorC, support)

    ratio = exp(support.lograR + support.logmlikcandidate - support.logmlik)

    if ratio >= 1 || ((ratio > 0) && (rand() <= ratio))
      performbrwmove!(i, hi, hj, support, state)
    end
  elseif k > state.k
    initsupportbrwsplit!(k, i, hi, data, priorC, settings, support, state)

    support.lograR = logratiopriorrowsplit(k, state.v[hi], priorR)

    updatelogmargliki!(priorC, support)
    updatelogmarglikj!(priorC, support)

    logmarglikbrwsplit!(state.cl, state.k, hi, priorC, support)

    ratio = exp(support.lograR + support.logmlikcandidate - support.logmlik)

    if ratio >= 1 || ((ratio > 0) && (rand() <= ratio))
      performbrwsplit!(i, hi, settings, support, state)
    end
  else
    hj = state.cl[v] < hi ? state.cl[v] : state.cl[v + 1]

    initsupportbrwmerge!(i, hj, data, support, state)

    support.lograR = logratiopriorrowmerge(k, state.v[hj], priorR)

    updatelogmarglikj!(priorC, support)

    logmarglikbrwmerge!(state.cl, state.k, hi, hj, priorC, support)

    ratio = exp(support.lograR + support.logmlikcandidate - support.logmlik)

    if ratio >= 1 || ((ratio > 0) && (rand() <= ratio))
      performbrwmerge!(i, hi, hj, settings, support, state)
    end
  end

  nothing
end

function initsupportbrwmerge!(i::Int,
                              hj::Int,
                              data::Matrix{UInt8},
                              support::MCMCSupport,
                              state::AminoAcidState)
  support.vj = state.v[hj] + 1

  for b in 1:support.m
    support.nj[b] = state.n1s[hj, b] + float(data[b, i])
  end

  nothing
end

function initsupportbrwmove!(i::Int,
                             hi::Int,
                             hj::Int,
                             data::Matrix{UInt8},
                             support::MCMCSupport,
                             state::AminoAcidState)
  support.vi = state.v[hi] - 1
  support.vj = state.v[hj] + 1

  for b in 1:support.m
    support.ni[b] = state.n1s[hi, b] - float(data[b, i])
    support.nj[b] = state.n1s[hj, b] + float(data[b, i])
  end

  idx = 0
  for a in 1:state.v[hi]
    if state.unit[hi][a] != i
      idx += 1
      support.ui[idx] = state.unit[hi][a]
    end
  end

  nothing
end

function initsupportbrwsplit!(k::Int,
                              i::Int,
                              hi::Int,
                              data::Matrix{UInt8},
                              priorC::AminoAcidPriorCol,
                              settings::KSettings,
                              support::MCMCSupport,
                              state::AminoAcidState)
  resizesupport!(support, k)

  support.vi = state.v[hi] - 1
  support.vj = 1

  for b in 1:support.m
    support.nj[b] = float(data[b, i])
    support.ni[b] = state.n1s[hi, b] - support.nj[b]
  end

  idx = 0
  for a in 1:state.v[hi]
    if state.unit[hi][a] != i
      idx += 1
      support.ui[idx] = state.unit[hi][a]
    end
  end

  nothing
end

function performbrwmove!(i::Int,
                         hi::Int,
                         hj::Int,
                         support::MCMCSupport,
                         state::AminoAcidState)
  state.R[i] = hj

  state.v[hi] = support.vi
  state.v[hj] = support.vj

  for b in 1:support.m
    state.n1s[hi, b] = support.ni[b]
    state.n1s[hj, b] = support.nj[b]

    support.lp[1, hi, b] = support.lpi[1, b]
    support.lp[2, hi, b] = support.lpi[2, b]
    support.lp[3, hi, b] = support.lpi[3, b]
    support.lp[4, hi, b] = support.lpi[4, b]

    support.lp[1, hj, b] = support.lpj[1, b]
    support.lp[2, hj, b] = support.lpj[2, b]
    support.lp[3, hj, b] = support.lpj[3, b]
    support.lp[4, hj, b] = support.lpj[4, b]
  end

  copyto!(state.unit[hi], 1, support.ui, 1, support.vi)

  resize!(state.unit[hj], state.v[hj])
  state.unit[hj][state.v[hj]] = i

  state.logpR += support.lograR

  support.logmlik = support.logmlikcandidate

  nothing
end

function performbrwsplit!(i::Int,
                          hi::Int,
                          settings::KSettings,
                          support::MCMCSupport,
                          state::AminoAcidState)
  resizestate!(state, state.k + 1, settings)

  hj = findfirst(state.emptycluster)

  state.R[i] = hj

  state.emptycluster[hj] = false

  support.k = 0
  for a in 1:length(state.emptycluster)
    if !state.emptycluster[a]
      support.k += 1
      state.cl[support.k] = a
    end
  end

  state.k = support.k

  state.v[hi] = support.vi
  state.v[hj] = support.vj

  for b in 1:support.m
    state.n1s[hi, b] = support.ni[b]
    state.n1s[hj, b] = support.nj[b]

    support.lp[1, hi, b] = support.lpi[1, b]
    support.lp[2, hi, b] = support.lpi[2, b]
    support.lp[3, hi, b] = support.lpi[3, b]
    support.lp[4, hi, b] = support.lpi[4, b]

    support.lp[1, hj, b] = support.lpj[1, b]
    support.lp[2, hj, b] = support.lpj[2, b]
    support.lp[3, hj, b] = support.lpj[3, b]
    support.lp[4, hj, b] = support.lpj[4, b]
  end

  copyto!(state.unit[hi], 1, support.ui, 1, support.vi)

  resize!(state.unit[hj], 1)
  state.unit[hj][1] = i

  state.logpR += support.lograR

  support.logmlik = support.logmlikcandidate

  nothing
end

function performbrwmerge!(i::Int,
                          hi::Int,
                          hj::Int,
                          settings::KSettings,
                          support::MCMCSupport,
                          state::AminoAcidState)
  state.R[i] = hj

  state.emptycluster[hi] = true

  support.k = 0
  for a in 1:length(state.emptycluster)
    if !state.emptycluster[a]
      support.k += 1
      state.cl[support.k] = a
    end
  end

  state.k = support.k

  state.v[hj] = support.vj

  for b in 1:support.m
    state.n1s[hj, b] = support.nj[b]

    support.lp[1, hj, b] = support.lpj[1, b]
    support.lp[2, hj, b] = support.lpj[2, b]
    support.lp[3, hj, b] = support.lpj[3, b]
    support.lp[4, hj, b] = support.lpj[4, b]
  end

  resize!(state.unit[hj], state.v[hj])
  state.unit[hj][state.v[hj]] = i

  state.logpR += support.lograR

  support.logmlik = support.logmlikcandidate

  nothing
end
