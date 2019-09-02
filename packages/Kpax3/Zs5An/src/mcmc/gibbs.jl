# This file is part of Kpax3. License is MIT.

function gibbs!(data::Matrix{UInt8},
                priorR::PriorRowPartition,
                priorC::PriorColPartition,
                settings::KSettings,
                support::MCMCSupport,
                state::AminoAcidState)
  shuffleunits!(support.u)

  for a in support.u
    resizesupport!(support, state.k + 1)
    gibbsallocate!(a, data, priorR, priorC, settings, support, state)
  end

  nothing
end

function gibbsallocate!(i::Int,
                        data::Matrix{UInt8},
                        priorR::PriorRowPartition,
                        priorC::PriorColPartition,
                        settings::KSettings,
                        support::MCMCSupport,
                        state::AminoAcidState)
  hi = state.R[i]

  initsupportgibbs!(hi, priorR, state, support)

  hj = 0

  # normalizing constant
  logc = -Inf

  # temporary variables
  li = 0
  lj = 0

  g = 0
  y = 0.0
  v = 0

  if state.v[hi] > 1
    support.vi = state.v[hi] - 1

    li = support.k + 1
    lj = support.k + 2

    support.t[li] = clusterweight(support.vi, priorR)
    support.t[lj] = clusterweight(1, state.k, priorR)

    # there are three options:
    # 1) i put back into hi (likelihood does not change)
    # 2) i put into hj (remove i from hi and compute the singleton cluster)
    # 3) i put into another existing cluster (remove i from hi and compute the
    #                                         new likelihood)

    for b in 1:support.m
      # remove i from its cluster
      support.ni[b] = state.n1s[hi, b] - float(data[b, i])

      # support.lpi and support.lpj are large enough to be used as a storage
      # support.lpi will contain the global sum of clusters not containing i
      # support.lpj will contain sums associated with hi and hj
      support.lpi[1, b] = priorC.logγ[1]
      support.lpi[2, b] = priorC.logγ[2]
      support.lpi[3, b] = priorC.logγ[3]
      support.lpi[4, b] = priorC.logγ[3]

      for l in 1:support.k
        g = support.cl[l]
        y = state.n1s[g, b] + float(data[b, i])
        v = state.v[g] + 1
        gibbsupdateclustergmove!(y, v, b, l, g, state.k, priorC, support)
      end
      gibbsupdateclusteri!(state.k, b, li, priorC, support)
      gibbsupdateclusterj!(data[b, i], state.k + 1, b, li, lj, priorC, support)
    end

    gibbscomputeprobi!(li, support)
    for b in 1:support.m
      for l in 1:support.k
        gibbscomputeprobg!(b, l, li, support)
      end
      gibbscomputeprobj!(b, li, lj, support)
    end

    logc = gibbscomputenormconst(lj, support)

    l = gibbssamplecluster(logc, lj, support)

    # if l == li do nothing
    if l <= support.k
      gibbsmove!(i, hi, support.cl[l], li, l, data, priorR, support, state)
    elseif l == lj
      gibbssplit!(i, hi, li, lj, data, priorR, settings, support, state)
    end
  else
    # li and lj are the same
    lj = support.k + 1

    support.t[lj] = clusterweight(1, support.k, priorR)

    for b in 1:support.m
      # support.lpi and support.lpj are large enough to be used as a storage
      # support.lpi will contain the global sum of clusters not containing i
      # support.lpj will contain sums associated with hi and hj
      support.lpi[1, b] = priorC.logγ[1]
      support.lpi[2, b] = priorC.logγ[2]
      support.lpi[3, b] = priorC.logγ[3]

      for l in 1:support.k
        g = support.cl[l]
        y = state.n1s[g, b] + float(data[b, i])
        v = state.v[g] + 1
        gibbsupdateclustergmerge!(y, v, b, l, g, support.k, priorC, support)
      end
    end

    gibbscomputeprobi!(lj, support)
    for b in 1:support.m, l in 1:support.k
      gibbscomputeprobg!(b, l, support)
    end

    logc = gibbscomputenormconst(lj, support)

    l = gibbssamplecluster(logc, lj, support)

    # if l == lj do nothing
    if l <= support.k
      gibbsmerge!(i, hi, support.cl[l], l, data, priorR, support, state)
    end
  end

  nothing
end

function initsupportgibbs!(hi::Int,
                           priorR::PriorRowPartition,
                           state::AminoAcidState,
                           support::MCMCSupport)
  # initialize clusters other than hi
  g = 0
  support.k = 0
  for l in 1:state.k
    g = state.cl[l]
    if g != hi
      support.k += 1
      support.cl[support.k] = g
      support.t[support.k] = clusterweight(state.v[g], priorR)
    end
  end

  nothing
end

function gibbsupdateclustergmove!(y::Float64,
                                  v::Int,
                                  b::Int,
                                  l::Int,
                                  g::Int,
                                  k::Int,
                                  priorC::PriorColPartition,
                                  support::MCMCSupport)
  support.lpi[1, b] += support.lp[1, g, b]
  support.lpi[2, b] += support.lp[2, g, b]

  support.tmp[3] = priorC.logω[k][1] + support.lp[3, g, b]
  support.tmp[4] = priorC.logω[k][2] + support.lp[4, g, b]

  support.tmp[1] = if support.tmp[3] > support.tmp[4]
    support.tmp[3] + log1p(exp(support.tmp[4] - support.tmp[3]))
  else
    support.tmp[4] + log1p(exp(support.tmp[3] - support.tmp[4]))
  end

  support.lpi[3, b] += support.tmp[1]

  # when we move unit i to the singleton cluster, the total number of clusters
  # increases by one
  support.tmp[3] = priorC.logω[k + 1][1] + support.lp[3, g, b]
  support.tmp[4] = priorC.logω[k + 1][2] + support.lp[4, g, b]

  support.lpi[4, b] += if support.tmp[3] > support.tmp[4]
    support.tmp[3] + log1p(exp(support.tmp[4] - support.tmp[3]))
  else
    support.tmp[4] + log1p(exp(support.tmp[3] - support.tmp[4]))
  end

  support.lq[1, l, b] = logmarglik(y, v, priorC.A[1, b], priorC.B[1, b])
  support.lq[2, l, b] = logmarglik(y, v, priorC.A[2, b], priorC.B[2, b])
  support.lq[3, l, b] = logmarglik(y, v, priorC.A[3, b], priorC.B[3, b])
  support.lq[4, l, b] = logmarglik(y, v, priorC.A[4, b], priorC.B[4, b])

  support.tmp[3] = priorC.logω[k][1] + support.lq[3, l, b]
  support.tmp[4] = priorC.logω[k][2] + support.lq[4, l, b]

  support.tmp[2] = if support.tmp[3] > support.tmp[4]
    support.tmp[3] + log1p(exp(support.tmp[4] - support.tmp[3]))
  else
    support.tmp[4] + log1p(exp(support.tmp[3] - support.tmp[4]))
  end

  # we added extra elements to support.lpi and they should be subtracted
  support.lr[1, l, b] = support.lq[1, l, b] - support.lp[1, g, b]
  support.lr[2, l, b] = support.lq[2, l, b] - support.lp[2, g, b]
  support.lr[3, l, b] = support.tmp[2] - support.tmp[1]

  nothing
end

function gibbsupdateclustergmerge!(y::Float64,
                                   v::Int,
                                   b::Int,
                                   l::Int,
                                   g::Int,
                                   k::Int,
                                   priorC::PriorColPartition,
                                   support::MCMCSupport)
  support.lpi[1, b] += support.lp[1, g, b]
  support.lpi[2, b] += support.lp[2, g, b]

  support.tmp[3] = priorC.logω[k][1] + support.lp[3, g, b]
  support.tmp[4] = priorC.logω[k][2] + support.lp[4, g, b]

  support.tmp[1] = if support.tmp[3] > support.tmp[4]
    support.tmp[3] + log1p(exp(support.tmp[4] - support.tmp[3]))
  else
    support.tmp[4] + log1p(exp(support.tmp[3] - support.tmp[4]))
  end

  support.lpi[3, b] += support.tmp[1]

  support.lq[1, l, b] = logmarglik(y, v, priorC.A[1, b], priorC.B[1, b])
  support.lq[2, l, b] = logmarglik(y, v, priorC.A[2, b], priorC.B[2, b])
  support.lq[3, l, b] = logmarglik(y, v, priorC.A[3, b], priorC.B[3, b])
  support.lq[4, l, b] = logmarglik(y, v, priorC.A[4, b], priorC.B[4, b])

  support.tmp[3] = priorC.logω[k][1] + support.lq[3, l, b]
  support.tmp[4] = priorC.logω[k][2] + support.lq[4, l, b]

  support.tmp[2] = if support.tmp[3] > support.tmp[4]
    support.tmp[3] + log1p(exp(support.tmp[4] - support.tmp[3]))
  else
    support.tmp[4] + log1p(exp(support.tmp[3] - support.tmp[4]))
  end

  # we added extra elements to support.lpi and they should be subtracted
  support.lr[1, l, b] = support.lq[1, l, b] - support.lp[1, g, b]
  support.lr[2, l, b] = support.lq[2, l, b] - support.lp[2, g, b]
  support.lr[3, l, b] = support.tmp[2] - support.tmp[1]

  nothing
end

function gibbsupdateclusteri!(k::Int,
                              b::Int,
                              li::Int,
                              priorC::PriorColPartition,
                              support::MCMCSupport)
  y = support.ni[b]
  v = support.vi

  support.lq[1, li, b] = logmarglik(y, v, priorC.A[1, b], priorC.B[1, b])
  support.lq[2, li, b] = logmarglik(y, v, priorC.A[2, b], priorC.B[2, b])
  support.lq[3, li, b] = logmarglik(y, v, priorC.A[3, b], priorC.B[3, b])
  support.lq[4, li, b] = logmarglik(y, v, priorC.A[4, b], priorC.B[4, b])

  support.tmp[3] = priorC.logω[k][1] + support.lq[3, li, b]
  support.tmp[4] = priorC.logω[k][2] + support.lq[4, li, b]

  support.lpj[1, b] = if support.tmp[3] > support.tmp[4]
    support.tmp[3] + log1p(exp(support.tmp[4] - support.tmp[3]))
  else
    support.tmp[4] + log1p(exp(support.tmp[3] - support.tmp[4]))
  end

  nothing
end

function gibbsupdateclusterj!(y::UInt8,
                              k::Int,
                              b::Int,
                              li::Int,
                              lj::Int,
                              priorC::PriorColPartition,
                              support::MCMCSupport)
  # add i to the singleton cluster (increases k by one)
  support.tmp[3] = priorC.logω[k][1] + support.lq[3, li, b]
  support.tmp[4] = priorC.logω[k][2] + support.lq[4, li, b]

  support.lpj[2, b] = if support.tmp[3] > support.tmp[4]
    support.tmp[3] + log1p(exp(support.tmp[4] - support.tmp[3]))
  else
    support.tmp[4] + log1p(exp(support.tmp[3] - support.tmp[4]))
  end

  support.lq[1, lj, b] = logmarglik(y, 1, priorC.A[1, b], priorC.B[1, b])
  support.lq[2, lj, b] = logmarglik(y, 1, priorC.A[2, b], priorC.B[2, b])
  support.lq[3, lj, b] = logmarglik(y, 1, priorC.A[3, b], priorC.B[3, b])
  support.lq[4, lj, b] = logmarglik(y, 1, priorC.A[4, b], priorC.B[4, b])

  support.tmp[3] = priorC.logω[k][1] + support.lq[3, lj, b]
  support.tmp[4] = priorC.logω[k][2] + support.lq[4, lj, b]

  support.lpj[3, b] = if support.tmp[3] > support.tmp[4]
    support.tmp[3] + log1p(exp(support.tmp[4] - support.tmp[3]))
  else
    support.tmp[4] + log1p(exp(support.tmp[3] - support.tmp[4]))
  end

  nothing
end

function gibbscomputeprobg!(b::Int,
                            l::Int,
                            li::Int,
                            support::MCMCSupport)
  # take into consideration that cluster hi has changed
  support.tmp[1] = support.lpi[1, b] + support.lr[1, l, b] +
                   support.lq[1, li, b]
  support.tmp[2] = support.lpi[2, b] + support.lr[2, l, b] +
                   support.lq[2, li, b]
  support.tmp[3] = support.lpi[3, b] + support.lr[3, l, b] +
                   support.lpj[1, b]

  support.t[l] += if (support.tmp[1] >= support.tmp[2]) &&
                     (support.tmp[1] >= support.tmp[3])
                    support.tmp[1] +
                    log1p(exp(support.tmp[2] - support.tmp[1]) +
                          exp(support.tmp[3] - support.tmp[1]))
                  elseif (support.tmp[2] >= support.tmp[1]) &&
                         (support.tmp[2] >= support.tmp[3])
                    support.tmp[2] +
                    log1p(exp(support.tmp[1] - support.tmp[2]) +
                          exp(support.tmp[3] - support.tmp[2]))
                  else
                    support.tmp[3] +
                    log1p(exp(support.tmp[1] - support.tmp[3]) +
                          exp(support.tmp[2] - support.tmp[3]))
                  end

  nothing
end

function gibbscomputeprobg!(b::Int,
                            l::Int,
                            support::MCMCSupport)
  # when merging, cluster hi disappears
  support.tmp[1] = support.lpi[1, b] + support.lr[1, l, b]
  support.tmp[2] = support.lpi[2, b] + support.lr[2, l, b]
  support.tmp[3] = support.lpi[3, b] + support.lr[3, l, b]

  support.t[l] += if (support.tmp[1] >= support.tmp[2]) &&
                     (support.tmp[1] >= support.tmp[3])
                    support.tmp[1] +
                    log1p(exp(support.tmp[2] - support.tmp[1]) +
                          exp(support.tmp[3] - support.tmp[1]))
                  elseif (support.tmp[2] >= support.tmp[1]) &&
                         (support.tmp[2] >= support.tmp[3])
                    support.tmp[2] +
                    log1p(exp(support.tmp[1] - support.tmp[2]) +
                          exp(support.tmp[3] - support.tmp[2]))
                  else
                    support.tmp[3] +
                    log1p(exp(support.tmp[1] - support.tmp[3]) +
                          exp(support.tmp[2] - support.tmp[3]))
                  end
  nothing
end

function gibbscomputeprobi!(li::Int,
                            support::MCMCSupport)
  # cluster hi does not change => marginal likelihood does not change
  support.t[li] += support.logmlik
  nothing
end

function gibbscomputeprobj!(b::Int,
                            li::Int,
                            lj::Int,
                            support::MCMCSupport)
  support.tmp[1] = support.lpi[1, b] + support.lq[1, li, b] +
                   support.lq[1, lj, b]
  support.tmp[2] = support.lpi[2, b] + support.lq[2, li, b] +
                   support.lq[2, lj, b]
  support.tmp[3] = support.lpi[4, b] + support.lpj[2, b] + support.lpj[3, b]

  support.t[lj] += if (support.tmp[1] >= support.tmp[2]) &&
                      (support.tmp[1] >= support.tmp[3])
                     support.tmp[1] +
                     log1p(exp(support.tmp[2] - support.tmp[1]) +
                           exp(support.tmp[3] - support.tmp[1]))
                   elseif (support.tmp[2] >= support.tmp[1]) &&
                          (support.tmp[2] >= support.tmp[3])
                     support.tmp[2] +
                     log1p(exp(support.tmp[1] - support.tmp[2]) +
                           exp(support.tmp[3] - support.tmp[2]))
                   else
                     support.tmp[3] +
                     log1p(exp(support.tmp[1] - support.tmp[3]) +
                           exp(support.tmp[2] - support.tmp[3]))
                   end

  nothing
end

function gibbscomputenormconst(k::Int,
                               support::MCMCSupport)
  logc = -Inf
  y = 0.0

  for l in 1:k
    if support.t[l] > logc
      logc = support.t[l]
    end
  end

  for l in 1:k
    y += exp(support.t[l] - logc)
  end

  logc += log(y)

  logc
end

function gibbssamplecluster(logc::Float64,
                            k::Int,
                            support::MCMCSupport)
  # find the maximum index for which the following holds
  # c * p <= sum(t[1:l])
  q = logc + log(rand())

  g = 1
  y = support.t[g]

  while (q > y) && (g < k)
    g += 1
    y = support.t[g] + log1p(exp(y - support.t[g]))
  end

  g
end

function gibbsmerge!(i::Int,
                     hi::Int,
                     hj::Int,
                     lg::Int,
                     data::Matrix{UInt8},
                     priorR::PriorRowPartition,
                     support::MCMCSupport,
                     state::AminoAcidState)
  support.logmlik = support.t[lg] - clusterweight(state.v[hj], priorR)

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

  state.logpR += logratiopriorrowmerge(state.k, state.v[hj], priorR)

  state.v[hj] += 1

  resize!(state.unit[hj], state.v[hj])
  state.unit[hj][state.v[hj]] = i

  for b in 1:support.m
    state.n1s[hj, b] += float(data[b, i])

    support.lp[1, hj, b] = support.lq[1, lg, b]
    support.lp[2, hj, b] = support.lq[2, lg, b]
    support.lp[3, hj, b] = support.lq[3, lg, b]
    support.lp[4, hj, b] = support.lq[4, lg, b]
  end

  nothing
end

function gibbsmove!(i::Int,
                    hi::Int,
                    hj::Int,
                    li::Int,
                    lg::Int,
                    data::Matrix{UInt8},
                    priorR::PriorRowPartition,
                    support::MCMCSupport,
                    state::AminoAcidState)
  support.logmlik = support.t[lg] - clusterweight(state.v[hj], priorR)

  state.logpR += logratiopriorrowmove(state.v[hi], state.v[hj], priorR)

  state.R[i] = hj

  h = 0
  for a in 1:state.v[hi]
    if state.unit[hi][a] != i
      h += 1
      state.unit[hi][h] = state.unit[hi][a]
    end
  end

  state.v[hi] = support.vi
  state.v[hj] += 1

  resize!(state.unit[hj], state.v[hj])
  state.unit[hj][state.v[hj]] = i

  for b in 1:support.m
    state.n1s[hi, b] = support.ni[b]
    state.n1s[hj, b] += float(data[b, i])

    support.lp[1, hi, b] = support.lq[1, li, b]
    support.lp[2, hi, b] = support.lq[2, li, b]
    support.lp[3, hi, b] = support.lq[3, li, b]
    support.lp[4, hi, b] = support.lq[4, li, b]

    support.lp[1, hj, b] = support.lq[1, lg, b]
    support.lp[2, hj, b] = support.lq[2, lg, b]
    support.lp[3, hj, b] = support.lq[3, lg, b]
    support.lp[4, hj, b] = support.lq[4, lg, b]
  end

  nothing
end

function gibbssplit!(i::Int,
                     hi::Int,
                     li::Int,
                     lj::Int,
                     data::Matrix{UInt8},
                     priorR::PriorRowPartition,
                     settings::KSettings,
                     support::MCMCSupport,
                     state::AminoAcidState)
  resizestate!(state, state.k + 1, settings)

  support.logmlik = support.t[lj] - clusterweight(1, state.k, priorR)

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

  h = 0
  for a in 1:state.v[hi]
    if state.unit[hi][a] != i
      h += 1
      state.unit[hi][h] = state.unit[hi][a]
    end
  end

  state.logpR += logratiopriorrowsplit(state.k, state.v[hi], priorR)

  state.v[hi] = support.vi
  state.v[hj] = 1

  resize!(state.unit[hj], 1)
  state.unit[hj][1] = i

  for b in 1:support.m
    state.n1s[hi, b] = support.ni[b]
    state.n1s[hj, b] = float(data[b, i])

    support.lp[1, hi, b] = support.lq[1, li, b]
    support.lp[2, hi, b] = support.lq[2, li, b]
    support.lp[3, hi, b] = support.lq[3, li, b]
    support.lp[4, hi, b] = support.lq[4, li, b]

    support.lp[1, hj, b] = support.lq[1, lj, b]
    support.lp[2, hj, b] = support.lq[2, lj, b]
    support.lp[3, hj, b] = support.lq[3, lj, b]
    support.lp[4, hj, b] = support.lq[4, lj, b]
  end

  nothing
end
