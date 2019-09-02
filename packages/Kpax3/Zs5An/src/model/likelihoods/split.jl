# This file is part of Kpax3. License is MIT.

function logmargliksplit!(cl::Vector{Int},
                          k::Int,
                          hi::Int,
                          priorC::AminoAcidPriorCol,
                          support::MCMCSupport)
  support.k = 0
  for l in 1:k
    if cl[l] != hi
      # this cluster is not affected by the split
      support.k += 1
      support.cl[support.k] = cl[l]
    end
  end
  support.k += 2

  support.logmlikcandidate = 0.0
  g = 0
  tmp1 = zeros(Float64, 3)
  tmp2 = zeros(Float64, 2)
  for b in 1:size(support.lp, 3)
    tmp1[1] = priorC.logγ[1]
    tmp1[2] = priorC.logγ[2]
    tmp1[3] = priorC.logγ[3]

    for l in 1:(support.k - 2)
      g = support.cl[l]

      tmp1[1] += support.lp[1, g, b]
      tmp1[2] += support.lp[2, g, b]

      tmp2[1] = priorC.logω[support.k][1] + support.lp[3, g, b]
      tmp2[2] = priorC.logω[support.k][2] + support.lp[4, g, b]

      tmp1[3] += (tmp2[1] > tmp2[2]) ?
                 (tmp2[1] + log1p(exp(tmp2[2] - tmp2[1]))) :
                 (tmp2[2] + log1p(exp(tmp2[1] - tmp2[2])))
    end

    # new cluster i
    tmp1[1] += support.lpi[1, b]
    tmp1[2] += support.lpi[2, b]

    tmp2[1] = priorC.logω[support.k][1] + support.lpi[3, b]
    tmp2[2] = priorC.logω[support.k][2] + support.lpi[4, b]

    tmp1[3] += (tmp2[1] > tmp2[2]) ?
               (tmp2[1] + log1p(exp(tmp2[2] - tmp2[1]))) :
               (tmp2[2] + log1p(exp(tmp2[1] - tmp2[2])))

    # new cluster j
    tmp1[1] += support.lpj[1, b]
    tmp1[2] += support.lpj[2, b]

    tmp2[1] = priorC.logω[support.k][1] + support.lpj[3, b]
    tmp2[2] = priorC.logω[support.k][2] + support.lpj[4, b]

    tmp1[3] += (tmp2[1] > tmp2[2]) ?
               (tmp2[1] + log1p(exp(tmp2[2] - tmp2[1]))) :
               (tmp2[2] + log1p(exp(tmp2[1] - tmp2[2])))

    support.logmlikcandidate += if (tmp1[1] >= tmp1[2]) &&
                                   (tmp1[1] >= tmp1[3])
                                  tmp1[1] + log1p(exp(tmp1[2] - tmp1[1]) +
                                                  exp(tmp1[3] - tmp1[1]))
                                elseif (tmp1[2] >= tmp1[1]) &&
                                       (tmp1[2] >= tmp1[3])
                                  tmp1[2] + log1p(exp(tmp1[1] - tmp1[2]) +
                                                  exp(tmp1[3] - tmp1[2]))
                                else
                                  tmp1[3] + log1p(exp(tmp1[1] - tmp1[3]) +
                                                  exp(tmp1[2] - tmp1[3]))
                                end
  end

  nothing
end
