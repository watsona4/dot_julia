# This file is part of Kpax3. License is MIT.

function computelocalmode!(v::Vector{Int},
                           n1s::Matrix{Float64},
                           C::Matrix{UInt8},
                           cl::Vector{Int},
                           k::Int,
                           logpC::Vector{Float64},
                           priorC::PriorColPartition)
  fill!(logpC, 0.0)

  m = size(n1s, 2)

  tmp1 = zeros(Float64, 4)
  tmp2 = zeros(Float64, 2, k)
  tmp3 = 0x00

  lγ = zeros(Float64, 3)

  g = 0

  for b in 1:m
    lγ[1] = priorC.logγ[1]
    lγ[2] = priorC.logγ[2]
    lγ[3] = priorC.logγ[3]

    tmp1[1] = SpecialFunctions.lbeta(priorC.A[1, b], priorC.B[1, b])
    tmp1[2] = SpecialFunctions.lbeta(priorC.A[2, b], priorC.B[2, b])
    tmp1[3] = SpecialFunctions.lbeta(priorC.A[3, b], priorC.B[3, b]) -
              priorC.logω[k][1]
    tmp1[4] = SpecialFunctions.lbeta(priorC.A[4, b], priorC.B[4, b]) -
              priorC.logω[k][2]

    for l in 1:k
      g = cl[l]

      # noise
      lγ[1] += SpecialFunctions.lbeta(priorC.A[1, b] + n1s[g, b],
                                      priorC.B[1, b] + v[g] - n1s[g, b]) -
               tmp1[1]

      # weak signal
      lγ[2] += SpecialFunctions.lbeta(priorC.A[2, b] + n1s[g, b],
                                      priorC.B[2, b] + v[g] - n1s[g, b]) -
               tmp1[2]

      # strong signal but not characteristic
      tmp2[1, l] = SpecialFunctions.lbeta(priorC.A[3, b] + n1s[g, b],
                                          priorC.B[3, b] + v[g] - n1s[g, b]) -
                   tmp1[3]

      # strong signal and characteristic
      tmp2[2, l] = SpecialFunctions.lbeta(priorC.A[4, b] + n1s[g, b],
                                          priorC.B[4, b] + v[g] - n1s[g, b]) -
                   tmp1[4]

      if tmp2[1, l] >= tmp2[2, l]
        tmp3 = log1p(exp(tmp2[2, l] - tmp2[1, l]))
        lγ[3] += tmp2[1, l] + tmp3
        tmp2[1, l] = tmp3
      else
        tmp3 = log1p(exp(tmp2[1, l] - tmp2[2, l]))
        lγ[3] += tmp2[2, l] + tmp3
        tmp2[2, l] = tmp3
      end
    end

    if lγ[3] > lγ[2]
      if lγ[3] > lγ[1]
        logpC[1] += priorC.logγ[3]
        logpC[2] -= log1p(exp(lγ[1] - lγ[3]) + exp(lγ[2] - lγ[3]))
        for l in 1:k
          if tmp2[1, l] >= tmp2[2, l]
            C[cl[l], b] = 0x03
            logpC[1] += priorC.logω[k][1]
            logpC[2] -= tmp2[1, l]
          else
            C[cl[l], b] = 0x04
            logpC[1] += priorC.logω[k][2]
            logpC[2] -= tmp2[2, l]
          end
        end
      else
        logpC[1] += priorC.logγ[1]
        logpC[2] -= log1p(exp(lγ[2] - lγ[1]) + exp(lγ[3] - lγ[1]))
        for l in 1:k
          C[cl[l], b] = 0x01
        end
      end
    elseif lγ[2] > lγ[1]
      logpC[1] += priorC.logγ[2]
      logpC[2] -= log1p(exp(lγ[1] - lγ[2]) + exp(lγ[3] - lγ[2]))
      for l in 1:k
        C[cl[l], b] = 0x02
      end
    else
      logpC[1] += priorC.logγ[1]
      logpC[2] -= log1p(exp(lγ[2] - lγ[1]) + exp(lγ[3] - lγ[1]))
      for l in 1:k
        C[cl[l], b] = 0x01
      end
    end
  end

  nothing
end

function computelocalmode!(state::State,
                           priorC::PriorColPartition)
  fill!(state.logpC, 0.0)

  m = size(state.n1s, 2)
  k = state.k

  tmp1 = zeros(Float64, 4)
  tmp2 = zeros(Float64, 2, k)
  tmp3 = 0x00

  lγ = zeros(Float64, 3)

  g = 0

  for b in 1:m
    lγ[1] = priorC.logγ[1]
    lγ[2] = priorC.logγ[2]
    lγ[3] = priorC.logγ[3]

    tmp1[1] = SpecialFunctions.lbeta(priorC.A[1, b], priorC.B[1, b])
    tmp1[2] = SpecialFunctions.lbeta(priorC.A[2, b], priorC.B[2, b])
    tmp1[3] = SpecialFunctions.lbeta(priorC.A[3, b], priorC.B[3, b]) -
              priorC.logω[k][1]
    tmp1[4] = SpecialFunctions.lbeta(priorC.A[4, b], priorC.B[4, b]) -
              priorC.logω[k][2]

    for l in 1:k
      g = state.cl[l]

      # noise
      lγ[1] += SpecialFunctions.lbeta(priorC.A[1, b] + state.n1s[g, b],
                                      priorC.B[1, b] + state.v[g] -
                                      state.n1s[g, b]) - tmp1[1]

      # weak signal
      lγ[2] += SpecialFunctions.lbeta(priorC.A[2, b] + state.n1s[g, b],
                                      priorC.B[2, b] + state.v[g] -
                                      state.n1s[g, b]) - tmp1[2]

      # strong signal but not characteristic
      tmp2[1, l] = SpecialFunctions.lbeta(priorC.A[3, b] + state.n1s[g, b],
                                          priorC.B[3, b] + state.v[g] -
                                          state.n1s[g, b]) - tmp1[3]

      # strong signal and characteristic
      tmp2[2, l] = SpecialFunctions.lbeta(priorC.A[4, b] + state.n1s[g, b],
                                          priorC.B[4, b] + state.v[g] -
                                          state.n1s[g, b]) - tmp1[4]

      if tmp2[1, l] >= tmp2[2, l]
        tmp3 = log1p(exp(tmp2[2, l] - tmp2[1, l]))
        lγ[3] += tmp2[1, l] + tmp3
        tmp2[1, l] = tmp3
      else
        tmp3 = log1p(exp(tmp2[1, l] - tmp2[2, l]))
        lγ[3] += tmp2[2, l] + tmp3
        tmp2[2, l] = tmp3
      end
    end

    if lγ[3] > lγ[2]
      if lγ[3] > lγ[1]
        state.logpC[1] += priorC.logγ[3]
        state.logpC[2] -= log1p(exp(lγ[1] - lγ[3]) + exp(lγ[2] - lγ[3]))
        for l in 1:k
          if tmp2[1, l] >= tmp2[2, l]
            state.C[state.cl[l], b] = 0x03
            state.logpC[1] += priorC.logω[k][1]
            state.logpC[2] -= tmp2[1, l]
          else
            state.C[state.cl[l], b] = 0x04
            state.logpC[1] += priorC.logω[k][2]
            state.logpC[2] -= tmp2[2, l]
          end
        end
      else
        state.logpC[1] += priorC.logγ[1]
        state.logpC[2] -= log1p(exp(lγ[2] - lγ[1]) + exp(lγ[3] - lγ[1]))
        for l in 1:k
          state.C[state.cl[l], b] = 0x01
        end
      end
    elseif lγ[2] > lγ[1]
      state.logpC[1] += priorC.logγ[2]
      state.logpC[2] -= log1p(exp(lγ[1] - lγ[2]) + exp(lγ[3] - lγ[2]))
      for l in 1:k
        state.C[state.cl[l], b] = 0x02
      end
    else
      state.logpC[1] += priorC.logγ[1]
      state.logpC[2] -= log1p(exp(lγ[2] - lγ[1]) + exp(lγ[3] - lγ[1]))
      for l in 1:k
        state.C[state.cl[l], b] = 0x01
      end
    end
  end

  nothing
end
