# This file is part of Kpax3. License is MIT.

function samplenoise!(C::Matrix{UInt8},
                      logp::Vector{Float64},
                      cl,
                      k::Int,
                      b::Int,
                      x::Float64,
                      logγ::Vector{Float64})
  logp[1] += logγ[1]
  logp[2] += x

  for l in 1:k
    C[cl[l], b] = 0x01
  end

  nothing
end

function sampleweaksignal!(C::Matrix{UInt8},
                           logp::Vector{Float64},
                           cl,
                           k::Int,
                           b::Int,
                           x::Float64,
                           logγ::Vector{Float64})
  logp[1] += logγ[2]
  logp[2] += x

  for l in 1:k
    C[cl[l], b] = 0x02
  end

  nothing
end

function samplestrongsignal!(C::Matrix{UInt8},
                             logp::Vector{Float64},
                             cl,
                             k::Int,
                             b::Int,
                             x::Float64,
                             lω::Matrix{Float64},
                             priorC::AminoAcidPriorCol)
  logp[1] += priorC.logγ[3]
  logp[2] += x

  for l in 1:k
    if rand() <= exp(lω[1, l])
      C[cl[l], b] = 0x03

      logp[1] += priorC.logω[k][1]
      logp[2] += lω[1, l]
    else
      C[cl[l], b] = 0x04

      logp[1] += priorC.logω[k][2]
      logp[2] += lω[2, l]
    end
  end

  nothing
end

function computeclusterlogprobs!(logq::Matrix{Float64},
                                 lγ::Vector{Float64},
                                 lω::Matrix{Float64},
                                 b::Int,
                                 l::Int,
                                 y::Real,
                                 n::Real,
                                 priorC::AminoAcidPriorCol)
  k = size(lω, 2)

  logq[1, l] = logmarglik(y, n, priorC.A[1, b], priorC.B[1, b])
  logq[2, l] = logmarglik(y, n, priorC.A[2, b], priorC.B[2, b])
  logq[3, l] = priorC.logω[k][1] +
               logmarglik(y, n, priorC.A[3, b], priorC.B[3, b])
  logq[4, l] = priorC.logω[k][2] +
               logmarglik(y, n, priorC.A[4, b], priorC.B[4, b])

  lγ[1] += logq[1, l]
  lγ[2] += logq[2, l]

  if logq[3, l] > logq[4, l]
    tmp = log1p(exp(logq[4, l] - logq[3, l]))

    lγ[3] += logq[3, l] + tmp

    lω[1, l] = -tmp
    lω[2, l] = logq[4, l] - logq[3, l] - tmp
  else
    tmp = log1p(exp(logq[3, l] - logq[4, l]))

    lγ[3] += logq[4, l] + tmp

    lω[1, l] = logq[3, l] - logq[4, l] - tmp
    lω[2, l] = -tmp
  end

  nothing
end

function rpostpartitioncols!(C::Matrix{UInt8},
                             cl::Vector{Int},
                             k::Int,
                             v::Vector{Int},
                             n1s::Matrix{Float64},
                             priorC::AminoAcidPriorCol)
  logp = zeros(Float64, 2)

  logq = zeros(Float64, 4, k)

  lγ = zeros(Float64, 3)
  lω = zeros(Float64, 2, k)

  p = 0.0
  tmp = 0.0

  for b in 1:size(C, 2)
    lγ[1] = priorC.logγ[1]
    lγ[2] = priorC.logγ[2]
    lγ[3] = priorC.logγ[3]

    for l in 1:k
      computeclusterlogprobs!(logq, lγ, lω, b, l, n1s[cl[l], b], v[cl[l]],
                              priorC)
    end

    if (lγ[1] >= lγ[2]) && (lγ[1] >= lγ[3])
      tmp = lγ[1] + log1p(exp(lγ[2] - lγ[1]) + exp(lγ[3] - lγ[1]))
    elseif (lγ[2] >= lγ[1]) && (lγ[2] >= lγ[3])
      tmp = lγ[2] + log1p(exp(lγ[1] - lγ[2]) + exp(lγ[3] - lγ[2]))
    else
      tmp = lγ[3] + log1p(exp(lγ[1] - lγ[3]) + exp(lγ[2] - lγ[3]))
    end

    lγ[1] -= tmp
    lγ[2] -= tmp
    lγ[3] -= tmp

    p = rand()

    if p <= exp(lγ[1])
      samplenoise!(C, logp, cl, k, b, lγ[1], priorC.logγ)
    elseif p <= exp(lγ[1]) + exp(lγ[2])
      sampleweaksignal!(C, logp, cl, k, b, lγ[2], priorC.logγ)
    else
      samplestrongsignal!(C, logp, cl, k, b, lγ[3], lω, priorC)
    end
  end

  logp
end

function sampleC!(priorC::PriorColPartition,
                  state::AminoAcidState)
  state.logpC = rpostpartitioncols!(state.C, state.cl, state.k, state.v,
                                    state.n1s, priorC)

  state.loglik = loglikelihood(state.C, state.cl, state.k, state.v, state.n1s,
                               priorC)

  state.logpp = state.logpR + state.logpC[1] + state.loglik

  nothing
end
