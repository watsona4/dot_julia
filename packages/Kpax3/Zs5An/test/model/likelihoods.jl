# This file is part of Kpax3. License is MIT.

function test_likelihoods_marginal()
  for (α, β) in ([0.1, 0.1], [0.5, 0.5], [1.0, 1.0], [10.0, 10.0], [100.0, 100.0], [0.2, 0.1], [1.0, 0.5], [2.0, 1.0], [20.0, 10.0], [200.0, 100.0], [0.1, 0.2], [0.5, 1.0], [1.0, 2.0], [10.0, 20.0], [100.0, 200.0])
    for (n, y) in ([1.0, 0.0], [1.0, 1.0], [5.0, 0.0], [5.0, 1.0], [5.0,  3.0], [5.0,  5.0], [10.0, 0.0], [10.0, 1.0], [10.0,  5.0], [10.0, 10.0], [100.0, 0.0], [100.0, 1.0], [100.0, 10.0], [100.0, 100.0])
      logp = SpecialFunctions.lgamma(α + y) + SpecialFunctions.lgamma(β + n - y) - SpecialFunctions.lgamma(α + β + n) + SpecialFunctions.lgamma(α + β) - SpecialFunctions.lgamma(α) - SpecialFunctions.lgamma(β)

      logcp0 = log(β + n - y) - log(α + β + n)
      logcp1 = log(α + y) - log(α + β + n)

      @test isapprox(Kpax3.marglik(y, n, α, β), exp(logp), atol=ε)
      @test isapprox(Kpax3.logmarglik(y, n, α, β), logp, atol=ε)

      @test isapprox(Kpax3.condmarglik(0x00, y, n, α, β), exp(logcp0), atol=ε)
      @test isapprox(Kpax3.condmarglik(0x01, y, n, α, β), exp(logcp1), atol=ε)

      @test isapprox(Kpax3.logcondmarglik(0x00, y, n, α, β), logcp0, atol=ε)
      @test isapprox(Kpax3.logcondmarglik(0x01, y, n, α, β), logcp1, atol=ε)
    end
  end

  for (α, β) in ([0.1, 0.1], [0.5, 0.5], [1.0, 1.0], [10.0, 10.0], [100.0, 100.0], [0.2, 0.1], [1.0, 0.5], [2.0, 1.0], [20.0, 10.0], [200.0, 100.0], [0.1, 0.2], [0.5, 1.0], [1.0, 2.0], [10.0, 20.0], [100.0, 200.0])
    for (n, y) in ((1.0, [0.0, 0.0, 1.0, 0.0, 1.0]), (10.0, [2.0, 8.0, 5.0, 10.0, 0.0]), (100.0, [100.0, 2.0, 72.0, 34.0, 0.0]))
      m = length(y)
      n1s = cld(m, 2)

      a = fill(α, m)
      b = fill(β, m)

      q = Kpax3.marglik(y, n, a, b)
      logq = Kpax3.logmarglik(y, n, a, b)

      q0 = Kpax3.condmarglik(fill(0x00, m), y, n, a, b)
      logq0 = Kpax3.logcondmarglik(fill(0x00, m), y, n, a, b)

      q1 = Kpax3.condmarglik(fill(0x01, m), y, n, a, b)
      logq1 = Kpax3.logcondmarglik(fill(0x01, m), y, n, a, b)

      qx = Kpax3.condmarglik([fill(0x01, n1s); fill(0x00, m - n1s)], y, n, a, b)
      logqx = Kpax3.logcondmarglik([fill(0x01, n1s); fill(0x00, m - n1s)], y, n, a, b)

      logp = SpecialFunctions.lgamma.(a .+ y) .+ SpecialFunctions.lgamma.(b .+ n .- y) .- SpecialFunctions.lgamma.(a .+ b .+ n) .+ SpecialFunctions.lgamma.(a .+ b) .- SpecialFunctions.lgamma.(a) .- SpecialFunctions.lgamma.(b)

      logcp0 = log.(b .+ n .- y) .- log.(a .+ b .+ n)
      logcp1 = log.(a .+ y) .- log.(a .+ b .+ n)

      logcpx = log.([a[1:n1s] .+ y[1:n1s]; b[(n1s + 1):m] .+ n .- y[(n1s + 1):m]]) - log.(a .+ b .+ n)

      for i in 1:m
        @test isapprox(q[i], exp(logp[i]), atol=ε)
        @test isapprox(logq[i], logp[i], atol=ε)

        @test isapprox(q0[i], exp(logcp0[i]), atol=ε)
        @test isapprox(logq0[i], logcp0[i], atol=ε)

        @test isapprox(q1[i], exp(logcp1[i]), atol=ε)
        @test isapprox(logq1[i], logcp1[i], atol=ε)

        @test isapprox(qx[i], exp(logcpx[i]), atol=ε)
        @test isapprox(logqx[i], logcpx[i], atol=ε)
      end
    end
  end

  nothing
end

test_likelihoods_marginal()

function test_likelihoods_loglik()
  ifile = "data/read_proper_aa.fasta"
  ofile = "../build/test"

  settings = Kpax3.KSettings(ifile, ofile)

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

  R = [1; 1; 1; 4; 6; 6]

  state = Kpax3.AminoAcidState(data, R, priorR, priorC, settings)
  copyto!(state.R, R)

  # fill C with harmless wrong values, just in case
  state.C = UInt8[1 1 1 4 2 1 3 3 1 1 1 1 1 1 1 1 1 2;
                  0 0 2 0 2 0 2 0 0 0 0 2 1 1 0 3 0 4;
                  1 1 1 1 0 1 1 1 0 1 1 1 1 1 1 0 0 0;
                  1 1 1 3 2 1 3 4 1 1 1 1 1 1 1 1 1 2;
                  0 2 1 2 0 0 1 0 4 0 0 0 2 3 0 0 0 0;
                  1 1 1 3 2 1 4 3 1 1 1 1 1 1 1 1 1 2]

  state.emptycluster = [false; true; true; false; true; false]
  state.cl = [1; 4; 6; 0; 0; 0]
  state.k = 3

  state.v = [3; 0; 0; 1; 0; 2]

  state.n1s = zeros(Float64, n, m)
  state.n1s[1, :] .= vec(sum(float(data[:, R .== 1]), dims=2))
  state.n1s[4, :] .= vec(sum(float(data[:, R .== 4]), dims=2))
  state.n1s[6, :] .= vec(sum(float(data[:, R .== 6]), dims=2))

  state.unit = Vector{Int}[zeros(Int, n) for g in 1:n]
  state.unit[1] = [1; 2; 3; 0; 0; 0]
  state.unit[4] = [4; 0; 0; 0; 0; 0]
  state.unit[6] = [5; 6; 0; 0; 0; 0]

  support = Kpax3.MCMCSupport(state, priorC);

  priorR = Kpax3.EwensPitman(settings.α, settings.θ)
  priorC = Kpax3.AminoAcidPriorCol(data, settings.γ, settings.r)

  loglik = zeros(Float64, 3)

  linearidx = Int[state.C[1, b] + 4 * (b - 1) for b in 1:m]
  loglik[1] = sum(Kpax3.logmarglik(vec(state.n1s[1, :]), state.v[1], priorC.A[linearidx], priorC.B[linearidx]))

  linearidx = Int[state.C[4, b] + 4 * (b - 1) for b in 1:m]
  loglik[2] = sum(Kpax3.logmarglik(vec(state.n1s[4, :]), state.v[4], priorC.A[linearidx], priorC.B[linearidx]))

  linearidx = Int[state.C[6, b] + 4 * (b - 1) for b in 1:m]
  loglik[3] = sum(Kpax3.logmarglik(vec(state.n1s[6, :]), state.v[6], priorC.A[linearidx], priorC.B[linearidx]))

  ll = loglik[1] + loglik[2] + loglik[3]

  @test isapprox(Kpax3.loglikelihood(state.C, state.cl, state.k, state.v, state.n1s, priorC), ll, atol=ε)
  @test isapprox(Kpax3.loglikelihood(state.C, state.cl, state.k, support), ll, atol=ε)

  nothing
end

test_likelihoods_loglik()

function test_likelihoods_logmarginal()
  ifile = "data/read_proper_aa.fasta"
  ofile = "../build/test"

  settings = Kpax3.KSettings(ifile, ofile)

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

  R = [3; 3; 1; 1; 5; 5]
  g = sort(unique(R))
  k = length(g)
  len = maximum(g)

  C = ones(UInt8, len, m)

  emptycluster = trues(len)
  emptycluster[g] .= false

  cl = zeros(Int, len)
  cl[1:k] .= g

  v = zeros(Int, len)
  v[g] .= [2; 2; 2]

  n1s = zeros(Float64, len, m)
  n1s[1, :] .= vec(sum(float(data[:, R .== 1]), dims=2))
  n1s[3, :] .= vec(sum(float(data[:, R .== 3]), dims=2))
  n1s[5, :] .= vec(sum(float(data[:, R .== 5]), dims=2))

  unit = Vector{Int}[sum(R .== g) > 0 ? findall(R .== g) : [0] for g in 1:n]

  logpR = -6.5792512120101012129680384532548487186431884765625
  logpC = [-9.1948612277878307708078864379785954952239990234375;
           -7.2468962917275181467857692041434347629547119140625]
  loglik = -66.7559125873377894322402426041662693023681640625
  logpp = logpR + logpC[1] + loglik

  state = Kpax3.AminoAcidState(copy(R), copy(C), copy(emptycluster), copy(cl), k, copy(v), copy(n1s), deepcopy(unit), logpR, copy(logpC), loglik, logpp)

  support = Kpax3.MCMCSupport(state, priorC)

  logmlik = Kpax3.logmarglikelihood(state.cl, state.k, support.lp, priorC)

  lml = 0.0
  tmp = zeros(Float64, 3)
  for b in 1:m
    tmp[1] = priorC.logγ[1]
    tmp[2] = priorC.logγ[2]
    tmp[3] = priorC.logγ[3]

    for l in 1:k
      g = cl[l]

      tmp[1] += support.lp[1, g, b]
      tmp[2] += support.lp[2, g, b]
      tmp[3] += log(exp(priorC.logω[k][1] + support.lp[3, g, b]) + exp(priorC.logω[k][2] + support.lp[4, g, b]))
    end

    lml += log(exp(tmp[1]) + exp(tmp[2]) + exp(tmp[3]))
  end

  @test isapprox(logmlik, lml, atol=ε)

  nothing
end

test_likelihoods_logmarginal()
