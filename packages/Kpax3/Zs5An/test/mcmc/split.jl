# This file is part of Kpax3. License is MIT.

function test_mcmc_split_init()
  # split cluster 1
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

  priorR = Kpax3.EwensPitman(settings.α, settings.θ)
  priorC = Kpax3.AminoAcidPriorCol(data, settings.γ, settings.r)

  R = [13; 13; 13; 13; 13; 76]
  k = length(unique(R)) + 1

  ij = [1; 5]
  S = 3
  u = 4

  state = Kpax3.AminoAcidState(data, R, priorR, priorC, settings)
  support = Kpax3.MCMCSupport(state, priorC)

  Kpax3.initsupportsplit!(ij, k, data, priorC, settings, support)

  len = 4

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

  wi = zeros(Float64, 4, m)
  for col in 1:m
    wi[1, col] = priorC.logγ[1] + Kpax3.logmarglik(data[col, ij[1]], 1, priorC.A[1, col], priorC.B[1, col])
    wi[2, col] = priorC.logγ[2] + Kpax3.logmarglik(data[col, ij[1]], 1, priorC.A[2, col], priorC.B[2, col])
    wi[3, col] = priorC.logγ[3] + priorC.logω[k][1] + Kpax3.logmarglik(data[col, ij[1]], 1, priorC.A[3, col], priorC.B[3, col])
    wi[4, col] = priorC.logγ[3] + priorC.logω[k][2] + Kpax3.logmarglik(data[col, ij[1]], 1, priorC.A[4, col], priorC.B[4, col])
  end

  ci = Float64[log(sum(exp.(support.wi.w[:, b]))) for b in 1:m]

  wj = zeros(Float64, 4, m)
  for col in 1:m
    wj[1, col] = priorC.logγ[1] + Kpax3.logmarglik(data[col, ij[2]], 1, priorC.A[1, col], priorC.B[1, col])
    wj[2, col] = priorC.logγ[2] + Kpax3.logmarglik(data[col, ij[2]], 1, priorC.A[2, col], priorC.B[2, col])
    wj[3, col] = priorC.logγ[3] + priorC.logω[k][1] + Kpax3.logmarglik(data[col, ij[2]], 1, priorC.A[3, col], priorC.B[3, col])
    wj[4, col] = priorC.logγ[3] + priorC.logω[k][2] + Kpax3.logmarglik(data[col, ij[2]], 1, priorC.A[4, col], priorC.B[4, col])
  end

  cj = Float64[log(sum(exp.(support.wj.w[:, b]))) for b in 1:m]

  @test support.vi == 1
  @test support.ni == float(data[:, ij[1]])
  @test support.ui == [ij[1]; 0; 0; 0; 0; 0]

  @test maximum(abs.(support.wi.w - wi)) <= ε
  @test maximum(abs.(support.wi.c - ci)) <= ε
  @test support.wi.z == zeros(Float64, 4, m)

  @test support.vj == 1
  @test support.nj == float(data[:, ij[2]])
  @test support.uj == [ij[2]; 0; 0; 0; 0; 0]

  @test maximum(abs.(support.wj.w - wj)) <= ε
  @test maximum(abs.(support.wj.c - cj)) <= ε
  @test support.wj.z == zeros(Float64, 4, m)

  nothing
end

test_mcmc_split_init()

function test_mcmc_split_updatei()
  # move the first unit (u) to cluster 1
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

  priorR = Kpax3.EwensPitman(settings.α, settings.θ)
  priorC = Kpax3.AminoAcidPriorCol(data, settings.γ, settings.r)

  R = [13; 13; 13; 13; 13; 76]
  k = length(unique(R)) + 1

  ij = [1; 5]
  S = 3
  u = 4

  state = Kpax3.AminoAcidState(data, R, priorR, priorC, settings)
  support = Kpax3.MCMCSupport(state, priorC)

  Kpax3.initsupportsplit!(ij, k, data, priorC, settings, support)

  len = 4

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

  lcp = zeros(Float64, 2)
  for b in 1:m
    lcp[1] += Kpax3.computeclusteriseqprobs!(data[b, u], b, priorC, support)
    lcp[2] += Kpax3.computeclusterjseqprobs!(data[b, u], b, priorC, support)
  end
  Kpax3.updateclusteri!(u, data, support)

  wi = zeros(Float64, 4, m)
  for col in 1:m
    wi[1, col] = priorC.logγ[1] + Kpax3.logmarglik(data[col, ij[1]], 1, priorC.A[1, col], priorC.B[1, col]) + Kpax3.logcondmarglik(data[col, u], data[col, ij[1]], 1, priorC.A[1, col], priorC.B[1, col])
    wi[2, col] = priorC.logγ[2] + Kpax3.logmarglik(data[col, ij[1]], 1, priorC.A[2, col], priorC.B[2, col]) + Kpax3.logcondmarglik(data[col, u], data[col, ij[1]], 1, priorC.A[2, col], priorC.B[2, col])
    wi[3, col] = priorC.logγ[3] + priorC.logω[k][1] + Kpax3.logmarglik(data[col, ij[1]], 1, priorC.A[3, col], priorC.B[3, col]) + Kpax3.logcondmarglik(data[col, u], data[col, ij[1]], 1, priorC.A[3, col], priorC.B[3, col])
    wi[4, col] = priorC.logγ[3] + priorC.logω[k][2] + Kpax3.logmarglik(data[col, ij[1]], 1, priorC.A[4, col], priorC.B[4, col]) + Kpax3.logcondmarglik(data[col, u], data[col, ij[1]], 1, priorC.A[4, col], priorC.B[4, col])
  end
  zi = copy(wi)

  ci = Float64[log(sum(exp.(support.wi.w[:, b]))) for b in 1:m]

  wj = zeros(Float64, 4, m)
  zj = zeros(Float64, 4, m)
  for col in 1:m
    wj[1, col] = priorC.logγ[1] + Kpax3.logmarglik(data[col, ij[2]], 1, priorC.A[1, col], priorC.B[1, col])
    wj[2, col] = priorC.logγ[2] + Kpax3.logmarglik(data[col, ij[2]], 1, priorC.A[2, col], priorC.B[2, col])
    wj[3, col] = priorC.logγ[3] + priorC.logω[k][1] + Kpax3.logmarglik(data[col, ij[2]], 1, priorC.A[3, col], priorC.B[3, col])
    wj[4, col] = priorC.logγ[3] + priorC.logω[k][2] + Kpax3.logmarglik(data[col, ij[2]], 1, priorC.A[4, col], priorC.B[4, col])

    zj[1, col] = wj[1, col] + Kpax3.logcondmarglik(data[col, u], data[col, ij[2]], 1, priorC.A[1, col], priorC.B[1, col])
    zj[2, col] = wj[2, col] + Kpax3.logcondmarglik(data[col, u], data[col, ij[2]], 1, priorC.A[2, col], priorC.B[2, col])
    zj[3, col] = wj[3, col] + Kpax3.logcondmarglik(data[col, u], data[col, ij[2]], 1, priorC.A[3, col], priorC.B[3, col])
    zj[4, col] = wj[4, col] + Kpax3.logcondmarglik(data[col, u], data[col, ij[2]], 1, priorC.A[4, col], priorC.B[4, col])
  end

  cj = Float64[log(sum(exp.(support.wj.w[:, b]))) for b in 1:m]

  @test support.vi == 2
  @test support.ni == float(data[:, ij[1]]) + float(data[:, u])
  @test support.ui == [ij[1]; u; 0; 0; 0; 0]

  @test maximum(abs.(support.wi.w - wi)) <= ε
  @test maximum(abs.(support.wi.c - ci)) <= ε
  @test maximum(abs.(support.wi.z - zi)) <= ε

  @test support.vj == 1
  @test support.nj == float(data[:, ij[2]])
  @test support.uj == [ij[2]; 0; 0; 0; 0; 0]

  @test maximum(abs.(support.wj.w - wj)) <= ε
  @test maximum(abs.(support.wj.c - cj)) <= ε
  @test maximum(abs.(support.wj.z - zj)) <= ε

  nothing
end

function test_mcmc_split_updatej()
  # move the first unit (u) to cluster 2
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

  priorR = Kpax3.EwensPitman(settings.α, settings.θ)
  priorC = Kpax3.AminoAcidPriorCol(data, settings.γ, settings.r)

  R = [13; 13; 13; 13; 13; 76]
  k = length(unique(R)) + 1

  ij = [1; 5]
  S = 3
  u = 4

  state = Kpax3.AminoAcidState(data, R, priorR, priorC, settings)
  support = Kpax3.MCMCSupport(state, priorC)

  Kpax3.initsupportsplit!(ij, k, data, priorC, settings, support)

  len = 4

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

  lcp = zeros(Float64, 2)
  for b in 1:m
    lcp[1] += Kpax3.computeclusteriseqprobs!(data[b, u], b, priorC, support)
    lcp[2] += Kpax3.computeclusterjseqprobs!(data[b, u], b, priorC, support)
  end
  Kpax3.updateclusterj!(u, data, support)

  wi = zeros(Float64, 4, m)
  zi = zeros(Float64, 4, m)
  for col in 1:m
    wi[1, col] = priorC.logγ[1] + Kpax3.logmarglik(data[col, ij[1]], 1, priorC.A[1, col], priorC.B[1, col])
    wi[2, col] = priorC.logγ[2] + Kpax3.logmarglik(data[col, ij[1]], 1, priorC.A[2, col], priorC.B[2, col])
    wi[3, col] = priorC.logγ[3] + priorC.logω[k][1] + Kpax3.logmarglik(data[col, ij[1]], 1, priorC.A[3, col], priorC.B[3, col])
    wi[4, col] = priorC.logγ[3] + priorC.logω[k][2] + Kpax3.logmarglik(data[col, ij[1]], 1, priorC.A[4, col], priorC.B[4, col])

    zi[1, col] = wi[1, col] + Kpax3.logcondmarglik(data[col, u], data[col, ij[1]], 1, priorC.A[1, col], priorC.B[1, col])
    zi[2, col] = wi[2, col] + Kpax3.logcondmarglik(data[col, u], data[col, ij[1]], 1, priorC.A[2, col], priorC.B[2, col])
    zi[3, col] = wi[3, col] + Kpax3.logcondmarglik(data[col, u], data[col, ij[1]], 1, priorC.A[3, col], priorC.B[3, col])
    zi[4, col] = wi[4, col] + Kpax3.logcondmarglik(data[col, u], data[col, ij[1]], 1, priorC.A[4, col], priorC.B[4, col])
  end

  ci = Float64[log(sum(exp.(support.wi.w[:, b]))) for b in 1:m]

  wj = zeros(Float64, 4, m)
  for col in 1:m
    wj[1, col] = priorC.logγ[1] + Kpax3.logmarglik(data[col, ij[2]], 1, priorC.A[1, col], priorC.B[1, col]) + Kpax3.logcondmarglik(data[col, u], data[col, ij[2]], 1, priorC.A[1, col], priorC.B[1, col])
    wj[2, col] = priorC.logγ[2] + Kpax3.logmarglik(data[col, ij[2]], 1, priorC.A[2, col], priorC.B[2, col]) + Kpax3.logcondmarglik(data[col, u], data[col, ij[2]], 1, priorC.A[2, col], priorC.B[2, col])
    wj[3, col] = priorC.logγ[3] + priorC.logω[k][1] + Kpax3.logmarglik(data[col, ij[2]], 1, priorC.A[3, col], priorC.B[3, col]) + Kpax3.logcondmarglik(data[col, u], data[col, ij[2]], 1, priorC.A[3, col], priorC.B[3, col])
    wj[4, col] = priorC.logγ[3] + priorC.logω[k][2] + Kpax3.logmarglik(data[col, ij[2]], 1, priorC.A[4, col], priorC.B[4, col]) + Kpax3.logcondmarglik(data[col, u], data[col, ij[2]], 1, priorC.A[4, col], priorC.B[4, col])
  end
  zj = copy(wj)

  cj = Float64[log(sum(exp.(support.wj.w[:, b]))) for b in 1:m]

  @test support.vi == 1
  @test support.ni == float(data[:, ij[1]])
  @test support.ui == [ij[1]; 0; 0; 0; 0; 0]

  @test maximum(abs.(support.wi.w - wi)) <= ε
  @test maximum(abs.(support.wi.c - ci)) <= ε
  @test maximum(abs.(support.wi.z - zi)) <= ε

  @test support.vj == 2
  @test support.nj == float(data[:, ij[2]]) + float(data[:, u])
  @test support.uj == [ij[2]; u; 0; 0; 0; 0]

  @test maximum(abs.(support.wj.w - wj)) <= ε
  @test maximum(abs.(support.wj.c - cj)) <= ε
  @test maximum(abs.(support.wj.z - zj)) <= ε

  nothing
end

test_mcmc_split_updatej()

function test_mcmc_updatelogmarglik()
  # move the first unit (u) to cluster 2 (test inverse split operator)
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

  priorR = Kpax3.EwensPitman(settings.α, settings.θ)
  priorC = Kpax3.AminoAcidPriorCol(data, settings.γ, settings.r)

  R = [13; 13; 13; 13; 13; 76]
  k = length(unique(R)) + 1

  ij = [1; 4]
  S = 3
  u = 4

  ni = vec(sum(float(data[:, [1; 2; 3]]), dims=2))
  vi = 3

  nj = vec(sum(float(data[:, [4; 5]]), dims=2))
  vj = 2

  lpi = zeros(Float64, 4, m)
  lpj = zeros(Float64, 4, m)
  for b in 1:m
    lpi[1, b] = Kpax3.logmarglik(ni[b], vi, priorC.A[1, b], priorC.B[1, b])
    lpi[2, b] = Kpax3.logmarglik(ni[b], vi, priorC.A[2, b], priorC.B[2, b])
    lpi[3, b] = Kpax3.logmarglik(ni[b], vi, priorC.A[3, b], priorC.B[3, b])
    lpi[4, b] = Kpax3.logmarglik(ni[b], vi, priorC.A[4, b], priorC.B[4, b])

    lpj[1, b] = Kpax3.logmarglik(nj[b], vj, priorC.A[1, b], priorC.B[1, b])
    lpj[2, b] = Kpax3.logmarglik(nj[b], vj, priorC.A[2, b], priorC.B[2, b])
    lpj[3, b] = Kpax3.logmarglik(nj[b], vj, priorC.A[3, b], priorC.B[3, b])
    lpj[4, b] = Kpax3.logmarglik(nj[b], vj, priorC.A[4, b], priorC.B[4, b])
  end

  state = Kpax3.AminoAcidState(data, R, priorR, priorC, settings)
  support = Kpax3.MCMCSupport(state, priorC)

  Kpax3.initsupportsplit!(ij, k, data, priorC, settings, support)

  support.ni = copy(ni)
  support.vi = copy(vi)

  support.nj = copy(nj)
  support.vj = copy(vj)

  Kpax3.updatelogmargliki!(priorC, support)
  Kpax3.updatelogmarglikj!(priorC, support)

  @test support.lpi == lpi
  @test support.lpj == lpj

  fill!(support.lpi, 0.0)
  fill!(support.lpj, 0.0)

  Kpax3.updatelogmargliki!(ni, vi, priorC, support)
  Kpax3.updatelogmarglikj!(nj, vj, priorC, support)

  @test support.lpi == lpi
  @test support.lpj == lpj

  nothing
end

test_mcmc_updatelogmarglik()
