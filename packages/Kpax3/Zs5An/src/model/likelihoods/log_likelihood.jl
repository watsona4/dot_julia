# This file is part of Kpax3. License is MIT.

function loglikelihood(C::Matrix{UInt8},
                       cl::Vector{Int},
                       k::Int,
                       support::MCMCSupport)
  loglik = 0.0

  for b in 1:support.m, l in 1:k
    loglik += support.lp[C[cl[l], b], cl[l], b]
  end

  loglik
end

function loglikelihood(C::Matrix{UInt8},
                       cl::Vector{Int},
                       k::Int,
                       v::Vector{Int},
                       n1s::Matrix{Float64},
                       priorC::AminoAcidPriorCol)
  m = size(C, 2)
  loglik = 0.0

  # If array A has dimension (d_{1}, ..., d_{l}, ..., d_{L}), to access
  # element A[i_{1}, ..., i_{l}, ..., i_{L}] it is possible to use the
  # following linear index
  # lidx = i_{1} + d_{1} * (i_{2} - 1) + ... +
  #      + (d_{1} * ... * d_{l-1}) * (i_{l} - 1) + ... +
  #      + (d_{1} * ... * d_{L-1}) * (i_{L} - 1)
  #
  # A[i_{1}, ..., i_{l}, ..., i_{L}] == A[lidx]
  lidx = 0
  for b in 1:m
    for l in 1:k
      lidx = C[cl[l], b] + 4 * (b - 1)
      loglik += logmarglik(n1s[cl[l], b], v[cl[l]], priorC.A[lidx],
                           priorC.B[lidx])
    end
  end

  loglik
end

function logmarglikelihood(cl::Vector{Int},
                           k::Int,
                           lp::Array{Float64},
                           priorC::AminoAcidPriorCol)
  lml = 0.0

  g = 0
  tmp1 = zeros(Float64, 3)
  tmp2 = zeros(Float64, 2)
  for b in 1:size(lp, 3)
    tmp1[1] = priorC.logγ[1]
    tmp1[2] = priorC.logγ[2]
    tmp1[3] = priorC.logγ[3]

    for l in 1:k
      g = cl[l]

      tmp1[1] += lp[1, g, b]
      tmp1[2] += lp[2, g, b]

      tmp2[1] = priorC.logω[k][1] + lp[3, g, b]
      tmp2[2] = priorC.logω[k][2] + lp[4, g, b]

      tmp1[3] += (tmp2[1] > tmp2[2]) ?
                 (tmp2[1] + log1p(exp(tmp2[2] - tmp2[1]))) :
                 (tmp2[2] + log1p(exp(tmp2[1] - tmp2[2])))
    end

    lml += if (tmp1[1] >= tmp1[2]) && (tmp1[1] >= tmp1[3])
             tmp1[1] + log1p(exp(tmp1[2] - tmp1[1]) + exp(tmp1[3] - tmp1[1]))
           elseif (tmp1[2] >= tmp1[1]) && (tmp1[2] >= tmp1[3])
             tmp1[2] + log1p(exp(tmp1[1] - tmp1[2]) + exp(tmp1[3] - tmp1[2]))
           else
             tmp1[3] + log1p(exp(tmp1[1] - tmp1[3]) + exp(tmp1[2] - tmp1[3]))
           end
  end

  lml
end
