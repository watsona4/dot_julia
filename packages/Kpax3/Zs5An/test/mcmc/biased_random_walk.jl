# This file is part of Kpax3. License is MIT.

function test_mcmc_brw_init()
  ifile = "data/read_proper_aa.fasta"
  ofile = "../build/test"

  settings = Kpax3.KSettings(ifile, ofile, maxclust=2, maxunit=1)

  data = UInt8[0 0 0 0 0 1;
               1 1 1 1 1 0;
               0 0 1 0 1 1;
               1 1 0 1 0 0;
               1 1 0 0 0 0;
               0 0 0 1 1 0;
               1 1 1 0 0 0;
               0 0 0 1 1 1;
               0 0 1 0 0 0;
               1 0 0 1 0 1;
               0 1 0 0 1 0;
               0 0 0 0 0 1;
               1 1 1 0 0 0;
               0 0 0 1 1 0;
               1 1 0 0 1 1;
               0 0 1 1 0 0;
               1 1 0 1 0 0;
               0 0 1 0 1 1]

  (m, n) = size(data)

  # --------------------------
  # move unit 4 into cluster 1
  R = [13; 13; 13; 42; 42; 76]
  priorR = Kpax3.EwensPitman(settings.α, settings.θ)
  priorC = Kpax3.AminoAcidPriorCol(data, settings.γ, settings.r)
  state = Kpax3.AminoAcidState(data, R, priorR, priorC, settings)
  support = Kpax3.MCMCSupport(state, priorC)

  i = 4
  hi = 2
  hj = 1
  Kpax3.initsupportbrwmove!(i, hi, hj, data, support, state)

  @test support.vi == 1
  @test support.ni == float(data[:, 5])

  @test support.vj == 4
  @test support.nj == vec(sum(data[:, [1; 2; 3; 4]], dims=2))

  # --------------------------------
  # move unit 3 into its own cluster
  R = [13; 13; 13; 42; 42; 76]
  priorR = Kpax3.EwensPitman(settings.α, settings.θ)
  priorC = Kpax3.AminoAcidPriorCol(data, settings.γ, settings.r)
  state = Kpax3.AminoAcidState(data, R, priorR, priorC, settings)
  support = Kpax3.MCMCSupport(state, priorC)

  k = 4
  i = 3
  hi = 1
  Kpax3.initsupportbrwsplit!(k, i, hi, data, priorC, settings, support, state)

  len = 6

  g = 0
  lp = zeros(Float64, 4, len, m)
  for b in 1:m, l in 1:state.k
    g = state.cl[l]

    lp[1, g, b] = Kpax3.logmarglik(state.n1s[g, b], state.v[g], priorC.A[1, b], priorC.B[1, b])
    lp[2, g, b] = Kpax3.logmarglik(state.n1s[g, b], state.v[g], priorC.A[2, b], priorC.B[2, b])
    lp[3, g, b] = Kpax3.logmarglik(state.n1s[g, b], state.v[g], priorC.A[3, b], priorC.B[3, b])
    lp[4, g, b] = Kpax3.logmarglik(state.n1s[g, b], state.v[g], priorC.A[4, b], priorC.B[4, b])
  end
  @test support.lp == lp

  @test support.vi == 2
  @test support.ni == vec(sum(data[:, [1; 2]], dims=2))

  @test support.vj == 1
  @test support.nj == float(data[:, 3])

  # --------------------------------
  # move unit 6 into cluster 2
  R = [13; 13; 13; 42; 42; 76]
  priorR = Kpax3.EwensPitman(settings.α, settings.θ)
  priorC = Kpax3.AminoAcidPriorCol(data, settings.γ, settings.r)
  state = Kpax3.AminoAcidState(data, R, priorR, priorC, settings)
  support = Kpax3.MCMCSupport(state, priorC)

  i = 6
  hi = 3
  hj = 2
  Kpax3.initsupportbrwmerge!(i, hj, data, support, state)

  @test support.vj == 3
  @test support.nj == vec(sum(data[:, [4; 5; 6]], dims=2))

  nothing
end

test_mcmc_brw_init()

function test_mcmc_brw()
  ifile = "data/read_proper_aa.fasta"
  ofile = "../build/test"

  settings = Kpax3.KSettings(ifile, ofile, maxclust=1, maxunit=1, op=[0.0; 0.0; 1.0])

  data = UInt8[0 0 0 0 0 1;
               1 1 1 1 1 0;
               0 0 1 0 1 1;
               1 1 0 1 0 0;
               1 1 0 0 0 0;
               0 0 0 1 1 0;
               1 1 1 0 0 0;
               0 0 0 1 1 1;
               0 0 1 0 0 0;
               1 0 0 1 0 1;
               0 1 0 0 1 0;
               0 0 0 0 0 1;
               1 1 1 0 0 0;
               0 0 0 1 1 0;
               1 1 0 0 1 1;
               0 0 1 1 0 0;
               1 1 0 1 0 0;
               0 0 1 0 1 1]

  (m, n) = size(data)

  priorR = Kpax3.EwensPitman(settings.α, settings.θ)
  priorC = Kpax3.AminoAcidPriorCol(data, settings.γ, settings.r)

  # [2; 2; 2; 1; 1; 3] => [2; 2; 2; 1; 1; 1]
  state1 = Kpax3.AminoAcidState(data, [2; 2; 2; 1; 1; 3], priorR, priorC, settings)
  support1 = Kpax3.MCMCSupport(state1, priorC)

  state2 = Kpax3.AminoAcidState(data, [2; 2; 2; 1; 1; 1], priorR, priorC, settings)
  support2 = Kpax3.MCMCSupport(state2, priorC)

  i = 6
  hi = state1.R[i]
  hj = state1.R[5]

  Kpax3.initsupportbrwmerge!(i, hj, data, support1, state1)

  support1.lograR = Kpax3.logratiopriorrowmerge(state2.k, state1.v[hj], priorR)

  Kpax3.updatelogmarglikj!(priorC, support1)

  Kpax3.logmarglikbrwmerge!(state1.cl, state1.k, hi, hj, priorC, support1)

  Kpax3.performbrwmerge!(i, hi, hj, settings, support1, state1)

  @test state1.R == state2.R
  @test state1.k == state2.k

  @test !state1.emptycluster[1]
  @test state1.cl[1] == state2.cl[1]
  @test state1.v[1] == state2.v[1]
  @test state1.n1s[1, :] == state2.n1s[1, :]
  @test state1.unit[1][1:state1.v[1]] == [4; 5; 6]

  @test !state1.emptycluster[2]
  @test state1.cl[2] == state2.cl[2]
  @test state1.v[2] == state2.v[2]
  @test state1.n1s[2, :] == state2.n1s[2, :]
  @test state1.unit[2][1:state1.v[2]] == [1; 2; 3]

  @test state1.emptycluster[3]

  @test isapprox(state1.logpR, state2.logpR, atol=ε)

  @test isapprox(support1.logmlik, support2.logmlik, atol=ε)

  # [2; 2; 2; 1; 1; 3] => [2; 2; 3; 1; 1; 3]
  state1 = Kpax3.AminoAcidState(data, [2; 2; 2; 1; 1; 3], priorR, priorC, settings)
  support1 = Kpax3.MCMCSupport(state1, priorC)

  state2 = Kpax3.AminoAcidState(data, [2; 2; 3; 1; 1; 3], priorR, priorC, settings)
  support2 = Kpax3.MCMCSupport(state2, priorC)

  i = 3
  hi = state1.R[i]
  hj = state1.R[6]

  Kpax3.initsupportbrwmove!(i, hi, hj, data, support1, state1)

  support1.lograR = Kpax3.logratiopriorrowmove(state1.v[hi], state1.v[hj], priorR)

  Kpax3.updatelogmargliki!(priorC, support1)
  Kpax3.updatelogmarglikj!(priorC, support1)

  Kpax3.logmarglikbrwmove!(state1.cl, state1.k, hi, hj, priorC, support1)

  Kpax3.performbrwmove!(i, hi, hj, support1, state1)

  @test state1.R == state2.R
  @test state1.k == state2.k

  @test !state1.emptycluster[1]
  @test state1.cl[1] == state2.cl[1]
  @test state1.v[1] == state2.v[1]
  @test state1.n1s[1, :] == state2.n1s[1, :]
  @test state1.unit[1][1:state1.v[1]] == [4; 5]

  @test !state1.emptycluster[2]
  @test state1.cl[2] == state2.cl[2]
  @test state1.v[2] == state2.v[2]
  @test state1.n1s[2, :] == state2.n1s[2, :]
  @test state1.unit[2][1:state1.v[2]] == [1; 2]

  @test !state1.emptycluster[3]
  @test state1.cl[3] == state2.cl[3]
  @test state1.v[3] == state2.v[3]
  @test state1.n1s[3, :] == state2.n1s[3, :]
  @test state1.unit[3][1:state1.v[3]] == [6; 3]

  @test isapprox(state1.logpR, state2.logpR, atol=ε)

  @test isapprox(support1.logmlik, support2.logmlik, atol=ε)

  # [3; 3; 3; 2; 2; 4] => [3; 3; 1; 2; 2; 4]
  state1 = Kpax3.AminoAcidState(data, [3; 3; 3; 2; 2; 4], priorR, priorC, settings)
  Kpax3.resizestate!(state1, 4, settings)

  state1.R = [3; 3; 3; 2; 2; 4]

  state1.emptycluster[1] = true
  state1.emptycluster[2:4] .= false
  state1.cl[1:3] .= [2; 3; 4]
  state1.k = 3

  state1.v[2:4] = copy(state1.v[1:3])
  state1.n1s[2:4, :] = copy(state1.n1s[1:3, :])
  state1.unit[4] = copy(state1.unit[3])
  state1.unit[3] = copy(state1.unit[2])
  state1.unit[2] = copy(state1.unit[1])

  support1 = Kpax3.MCMCSupport(state1, priorC)

  state2 = Kpax3.AminoAcidState(data, [3; 3; 1; 2; 2; 4], priorR, priorC, settings)
  support2 = Kpax3.MCMCSupport(state2, priorC)

  k = state2.k
  i = 3
  hi = state1.R[i]

  Kpax3.initsupportbrwsplit!(k, i, hi, data, priorC, settings, support1, state1)

  support1.lograR = Kpax3.logratiopriorrowsplit(k, state1.v[hi], priorR)

  Kpax3.updatelogmargliki!(priorC, support1)
  Kpax3.updatelogmarglikj!(priorC, support1)

  Kpax3.logmarglikbrwsplit!(state1.cl, state1.k, hi, priorC, support1)

  Kpax3.performbrwsplit!(i, hi, settings, support1, state1)

  @test state1.R == state2.R
  @test state1.k == state2.k

  @test !state1.emptycluster[1]
  @test state1.cl[1] == state2.cl[1]
  @test state1.v[1] == state2.v[1]
  @test state1.n1s[1, :] == state2.n1s[1, :]
  @test state1.unit[1][1:state1.v[1]] == [i]

  @test !state1.emptycluster[2]
  @test state1.cl[2] == state2.cl[2]
  @test state1.v[2] == state2.v[2]
  @test state1.n1s[2, :] == state2.n1s[2, :]
  @test state1.unit[2][1:state1.v[2]] == [4; 5]

  @test !state1.emptycluster[3]
  @test state1.cl[3] == state2.cl[3]
  @test state1.v[3] == state2.v[3]
  @test state1.n1s[3, :] == state2.n1s[3, :]
  @test state1.unit[3][1:state1.v[3]] == [1; 2]

  @test !state1.emptycluster[4]
  @test state1.cl[4] == state2.cl[4]
  @test state1.v[4] == state2.v[4]
  @test state1.n1s[4, :] == state2.n1s[4, :]
  @test state1.unit[4][1:state1.v[4]] == [6]

  @test isapprox(state1.logpR,state2.logpR, atol=ε)

  @test isapprox(support1.logmlik, support2.logmlik, atol=ε)

  # [2; 2; 2; 1; 1; 3] => [2; 2; 4; 1; 1; 3]
  # allocate new resources
  state1 = Kpax3.AminoAcidState(data, [2; 2; 2; 1; 1; 3], priorR, priorC, settings)
  support1 = Kpax3.MCMCSupport(state1, priorC)

  state2 = Kpax3.AminoAcidState(data, [2; 2; 4; 1; 1; 3], priorR, priorC, settings)
  support2 = Kpax3.MCMCSupport(state2, priorC)

  k = state2.k
  i = 3
  hi = state1.R[i]

  Kpax3.initsupportbrwsplit!(k, i, hi, data, priorC, settings, support1, state1)

  support1.lograR = Kpax3.logratiopriorrowsplit(k, state1.v[hi], priorR)

  Kpax3.updatelogmargliki!(priorC, support1)
  Kpax3.updatelogmarglikj!(priorC, support1)

  Kpax3.logmarglikbrwsplit!(state1.cl, state1.k, hi, priorC, support1)

  Kpax3.performbrwsplit!(i, hi, settings, support1, state1)

  @test state1.R == state2.R
  @test state1.k == state2.k

  @test !state1.emptycluster[1]
  @test state1.cl[1] == state2.cl[1]
  @test state1.v[1] == state2.v[1]
  @test state1.n1s[1, :] == state2.n1s[1, :]
  @test state1.unit[1][1:state1.v[1]] == [4; 5]

  @test !state1.emptycluster[2]
  @test state1.cl[2] == state2.cl[2]
  @test state1.v[2] == state2.v[2]
  @test state1.n1s[2, :] == state2.n1s[2, :]
  @test state1.unit[2][1:state1.v[2]] == [1; 2]

  @test !state1.emptycluster[3]
  @test state1.cl[3] == state2.cl[3]
  @test state1.v[3] == state2.v[3]
  @test state1.n1s[3, :] == state2.n1s[3, :]
  @test state1.unit[3][1:state1.v[3]] == [6]

  @test !state1.emptycluster[4]
  @test state1.cl[4] == state2.cl[4]
  @test state1.v[4] == state2.v[4]
  @test state1.n1s[4, :] == state2.n1s[4, :]
  @test state1.unit[4][1:state1.v[4]] == [i]

  @test isapprox(state1.logpR, state2.logpR, atol=ε)

  @test isapprox(support1.logmlik, support2.logmlik, atol=ε)

  nothing
end

test_mcmc_brw()
