# This file is part of Kpax3. License is MIT.

"""
logp(C | R)
"""
function logpriorC(C::Matrix{UInt8},
                   cl::Vector{Int},
                   k::Int,
                   priorC::AminoAcidPriorCol)
  logp = 0.0

  for b in 1:size(C, 2)
    if C[cl[1], b] == UInt8(1)
      logp += priorC.logγ[1]
    elseif C[cl[1], b] == UInt8(2)
      logp += priorC.logγ[2]
    else
      logp += priorC.logγ[3]

      for l in 1:k
        if C[cl[l], b] == UInt8(3)
          logp += priorC.logω[k][1]
        else
          logp += priorC.logω[k][2]
        end
      end
    end
  end

  logp
end

function logpriorC(C::Matrix{UInt8},
                   k::Int,
                   priorC::AminoAcidPriorCol)
  logp = 0.0

  for b in 1:size(C, 2)
    if C[1, b] == UInt8(1)
      logp += priorC.logγ[1]
    elseif C[1, b] == UInt8(2)
      logp += priorC.logγ[2]
    else
      logp += priorC.logγ[3]

      for l in 1:k
        if C[l, b] == UInt8(3)
          logp += priorC.logω[k][1]
        else
          logp += priorC.logω[k][2]
        end
      end
    end
  end

  logp
end

"""
logp(S | R, X)
"""
function logcondpostS(S::Vector{UInt8},
                      cl::Vector{Int},
                      k::Int,
                      v::Vector{Int},
                      n1s::Matrix{Float64},
                      priorC::AminoAcidPriorCol)
  logp = 0.0

  lγ = zeros(Float64, 3)

  g = 0
  tmp1 = zeros(Float64, 2)
  tmp2 = 0.0

  for b in 1:length(S)
    lγ[1] = priorC.logγ[1]
    lγ[2] = priorC.logγ[2]
    lγ[3] = priorC.logγ[3]

    for l in 1:k
      g = cl[l]

      lγ[1] += logmarglik(n1s[g, b], v[g], priorC.A[1, b], priorC.B[1, b])
      lγ[2] += logmarglik(n1s[g, b], v[g], priorC.A[2, b], priorC.B[2, b])

      tmp1[1] = priorC.logω[k][1] +
                logmarglik(n1s[g, b], v[g], priorC.A[3, b], priorC.B[3, b])

      tmp1[2] = priorC.logω[k][2] +
                logmarglik(n1s[g, b], v[g], priorC.A[4, b], priorC.B[4, b])

      if tmp1[1] > tmp1[2]
        lγ[3] += tmp1[1] + log1p(exp(tmp1[2] - tmp1[1]))
      else
        lγ[3] += tmp1[2] + log1p(exp(tmp1[1] - tmp1[2]))
      end
    end

    if (lγ[1] >= lγ[2]) && (lγ[1] >= lγ[3])
      tmp2 = lγ[1] + log1p(exp(lγ[2] - lγ[1]) + exp(lγ[3] - lγ[1]))
    elseif (lγ[2] >= lγ[1]) && (lγ[2] >= lγ[3])
      tmp2 = lγ[2] + log1p(exp(lγ[1] - lγ[2]) + exp(lγ[3] - lγ[2]))
    else
      tmp2 = lγ[3] + log1p(exp(lγ[1] - lγ[3]) + exp(lγ[2] - lγ[3]))
    end

    logp += (lγ[S[b]] - tmp2)
  end

  logp
end

"""
Logp(C | R, X)
"""
function logcondpostC(C::Matrix{UInt8},
                      cl::Vector{Int},
                      k::Int,
                      v::Vector{Int},
                      n1s::Matrix{Float64},
                      priorC::AminoAcidPriorCol)
  logp = 0.0

  lγ = zeros(Float64, 3)

  logq = zeros(Float64, 4, length(cl))

  g = 0
  tmp = 0.0

  for b in 1:size(C, 2)
    lγ[1] = priorC.logγ[1]
    lγ[2] = priorC.logγ[2]
    lγ[3] = priorC.logγ[3]

    for l in 1:k
      g = cl[l]

      logq[1, l] = logmarglik(n1s[g, b], v[g], priorC.A[1, b], priorC.B[1, b])
      logq[2, l] = logmarglik(n1s[g, b], v[g], priorC.A[2, b], priorC.B[2, b])
      logq[3, l] = priorC.logω[k][1] +
                   logmarglik(n1s[g, b], v[g], priorC.A[3, b], priorC.B[3, b])
      logq[4, l] = priorC.logω[k][2] +
                   logmarglik(n1s[g, b], v[g], priorC.A[4, b], priorC.B[4, b])

      lγ[1] += logq[1, l]
      lγ[2] += logq[2, l]

      if logq[3, l] > logq[4, l]
        tmp = log1p(exp(logq[4, l] - logq[3, l]))

        lγ[3] += logq[3, l] + tmp

        if C[g, b] == 0x03
          logp -= tmp
        elseif C[g, b] == 0x04
          logp += logq[4, l] - logq[3, l] - tmp
        end
      else
        tmp = log1p(exp(logq[3, l] - logq[4, l]))

        lγ[3] += logq[4, l] + tmp

        if C[g, b] == 0x03
          logp += logq[3, l] - logq[4, l] - tmp
        elseif C[g, b] == 0x04
          logp -= tmp
        end
      end
    end

    if (lγ[1] >= lγ[2]) && (lγ[1] >= lγ[3])
      tmp = lγ[1] + log1p(exp(lγ[2] - lγ[1]) + exp(lγ[3] - lγ[1]))
    elseif (lγ[2] >= lγ[1]) && (lγ[2] >= lγ[3])
      tmp = lγ[2] + log1p(exp(lγ[1] - lγ[2]) + exp(lγ[3] - lγ[2]))
    else
      tmp = lγ[3] + log1p(exp(lγ[1] - lγ[3]) + exp(lγ[2] - lγ[3]))
    end

    if C[cl[1], b] == 0x01
      logp += lγ[1] - tmp
    elseif C[cl[1], b] == 0x02
      logp += lγ[2] - tmp
    else
      logp += lγ[3] - tmp
    end
  end

  logp
end
