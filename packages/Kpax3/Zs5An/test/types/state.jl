# This file is part of Kpax3. License is MIT.

# TODO: How to test properly initializestate?

function test_state_constructor()
  ifile = "data/read_proper_aa.fasta"
  ofile = "../build/test"

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

  # test constructor
  settings = Kpax3.KSettings(ifile, ofile, maxclust=1, maxunit=1)

  R = [13; 13; 42; 42; 76; 76]

  k = length(unique(R))
  maxclust = max(k, min(n, settings.maxclust))

  emptycluster = trues(maxclust)
  emptycluster[1:k] .= false

  cl = zeros(Int, maxclust)
  cl[1:k] .= findall(.!emptycluster)

  v = zeros(Int, maxclust)
  v[1:k] .= [2; 2; 2]

  n1s = zeros(Float64, maxclust, m)
  n1s[1, :] .= vec(sum(float(data[:, R .== 13]), dims=2))
  n1s[2, :] .= vec(sum(float(data[:, R .== 42]), dims=2))
  n1s[3, :] .= vec(sum(float(data[:, R .== 76]), dims=2))

  priorR = Kpax3.EwensPitman(settings.α, settings.θ)
  priorC = Kpax3.AminoAcidPriorCol(data, settings.γ, settings.r)

  state = Kpax3.AminoAcidState(data, R, priorR, priorC, settings)

  @test state.R == [1; 1; 2; 2; 3; 3]

  @test isa(state.C, Matrix{UInt8})
  @test size(state.C, 1) == maxclust
  @test size(state.C, 2) == m

  @test state.emptycluster == emptycluster
  @test state.cl == cl
  @test state.k == k

  @test state.v == v
  @test state.n1s == n1s
  @test state.unit == Vector{Int}[sum(state.R .== g) > 0 ? findall(state.R .== g) : [0] for g in 1:maxclust]

  @test state.logpR == Kpax3.logdPriorRow(n, k, v, priorR)
  @test isapprox(state.logpC[1], Kpax3.logpriorC(state.C, state.cl, state.k, priorC), atol=ε)
  @test isapprox(state.logpC[2], Kpax3.logcondpostC(state.C, state.cl, state.k, state.v, state.n1s, priorC), atol=ε)

  loglik = zeros(Float64, 3)

  linearidx = Int[state.C[cl[1], b] + 4 * (b - 1) for b in 1:m]
  loglik[1] = sum(Kpax3.logmarglik(vec(state.n1s[cl[1], :]), state.v[cl[1]], priorC.A[linearidx], priorC.B[linearidx]))

  linearidx = Int[state.C[cl[2], b] + 4 * (b - 1) for b in 1:m]
  loglik[2] = sum(Kpax3.logmarglik(vec(state.n1s[cl[2], :]), state.v[cl[2]], priorC.A[linearidx], priorC.B[linearidx]))

  linearidx = Int[state.C[cl[3], b] + 4 * (b - 1) for b in 1:m]
  loglik[3] = sum(Kpax3.logmarglik(vec(state.n1s[cl[3], :]), state.v[cl[3]], priorC.A[linearidx], priorC.B[linearidx]))

  ll = loglik[1] + loglik[2] + loglik[3]
  @test isapprox(state.loglik, ll, atol=ε)

  @test isapprox(state.logpp, Kpax3.logdPriorRow(n, k, v, priorR) + Kpax3.logpriorC(state.C, state.cl, state.k, priorC) + ll, atol=ε)

  settings = Kpax3.KSettings("data/mcmc_6.fasta", "../build/test", maxclust=1, maxunit=1)
  x = Kpax3.AminoAcidData(settings)
  state = Kpax3.optimumstate(x, "data/mcmc_6.csv", settings)

  priorR = Kpax3.EwensPitman(settings.α, settings.θ)
  priorC = Kpax3.AminoAcidPriorCol(x.data, settings.γ, settings.r)

  n = 6
  R = [1; 1; 2; 2; 3; 4]

  maxclust = 4
  m = 4

  emptycluster = falses(4)
  cl = [1; 2; 3; 4]
  k = 4

  v = [2; 2; 1; 1]
  n1s = zeros(Float64, maxclust, m)
  n1s[1, :] .= vec(sum(float(x.data[:, R .== 1]), dims=2))
  n1s[2, :] .= vec(sum(float(x.data[:, R .== 2]), dims=2))
  n1s[3, :] .= vec(sum(float(x.data[:, R .== 3]), dims=2))
  n1s[4, :] .= vec(sum(float(x.data[:, R .== 4]), dims=2))

  @test state.R == R

  @test isa(state.C, Matrix{UInt8})
  @test size(state.C, 1) == maxclust
  @test size(state.C, 2) == m

  @test state.emptycluster == emptycluster
  @test state.cl == cl
  @test state.k == k

  @test state.v == v
  @test state.n1s == n1s
  @test state.unit == Vector{Int}[sum(state.R .== g) > 0 ? findall(state.R .== g) : [0] for g in 1:maxclust]

  @test state.logpR == Kpax3.logdPriorRow(n, k, v, priorR)
  @test isapprox(state.logpC[1], Kpax3.logpriorC(state.C, state.cl, state.k, priorC), atol=ε)
  @test isapprox(state.logpC[2], Kpax3.logcondpostC(state.C, state.cl, state.k, state.v, state.n1s, priorC), atol=ε)

  loglik = zeros(Float64, 4)

  linearidx = Int[state.C[cl[1], b] + 4 * (b - 1) for b in 1:m]
  loglik[1] = sum(Kpax3.logmarglik(vec(state.n1s[cl[1], :]), state.v[cl[1]], priorC.A[linearidx], priorC.B[linearidx]))

  linearidx = Int[state.C[cl[2], b] + 4 * (b - 1) for b in 1:m]
  loglik[2] = sum(Kpax3.logmarglik(vec(state.n1s[cl[2], :]), state.v[cl[2]], priorC.A[linearidx], priorC.B[linearidx]))

  linearidx = Int[state.C[cl[3], b] + 4 * (b - 1) for b in 1:m]
  loglik[3] = sum(Kpax3.logmarglik(vec(state.n1s[cl[3], :]), state.v[cl[3]], priorC.A[linearidx], priorC.B[linearidx]))

  linearidx = Int[state.C[cl[4], b] + 4 * (b - 1) for b in 1:m]
  loglik[4] = sum(Kpax3.logmarglik(vec(state.n1s[cl[4], :]), state.v[cl[4]], priorC.A[linearidx], priorC.B[linearidx]))

  ll = loglik[1] + loglik[2] + loglik[3] + loglik[4]
  @test isapprox(state.loglik, ll, atol=ε)

  @test isapprox(state.logpp, Kpax3.logdPriorRow(n, k, v, priorR) + Kpax3.logpriorC(state.C, state.cl, state.k, priorC) + ll, atol=ε)

  nothing
end

test_state_constructor()

function test_state_resizestate()
  ifile = "data/read_proper_aa.fasta"
  ofile = "../build/test"

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

  # resizestate!(state, k)
  # k < 2 * maxclust => len = maxclust
  settings = Kpax3.KSettings(ifile, ofile, maxclust=2, maxunit=1)

  priorR = Kpax3.EwensPitman(settings.α, settings.θ)
  priorC = Kpax3.AminoAcidPriorCol(data, settings.γ, settings.r)

  state = Kpax3.AminoAcidState(data, [1; 1; 1; 1; 1; 1], priorR, priorC, settings)

  len = 4

  R = copy(state.R)
  k = state.k

  C = zeros(UInt8, len, m)
  C[1, :] .= copy(vec(state.C[1, :]))

  emptycluster = trues(len)
  emptycluster[1] = false

  cl = zeros(Int, len)
  cl[1] = 1

  v = zeros(Int, len)
  v[1] = 6

  n1s = zeros(Float64, len, m)
  n1s[1, :] .= copy(vec(state.n1s[1, :]))

  unit = Vector{Int}[sum(state.R .== g) > 0 ? findall(state.R .== g) : [0] for g in 1:len]

  logpR = state.logpR
  logpC = copy(state.logpC)
  loglik = state.loglik
  logpp = state.logpp

  Kpax3.resizestate!(state, 3)

  @test state.R == R
  @test state.C == C
  @test state.emptycluster == emptycluster
  @test state.cl == cl
  @test state.k == k
  @test state.v == v
  @test state.n1s == n1s
  @test state.unit == unit
  @test state.logpR == logpR
  @test state.logpC == logpC
  @test state.loglik == loglik
  @test state.logpp == logpp

  # resizestate!(state, k)
  # k > 2 * maxclust => len = k
  settings = Kpax3.KSettings(ifile, ofile, maxclust=2, maxunit=1)

  priorR = Kpax3.EwensPitman(settings.α, settings.θ)
  priorC = Kpax3.AminoAcidPriorCol(data, settings.γ, settings.r)

  state = Kpax3.AminoAcidState(data, [1; 1; 1; 1; 1; 1], priorR, priorC, settings)

  len = 5

  R = copy(state.R)
  k = state.k

  C = zeros(UInt8, len, m)
  C[1, :] .= copy(vec(state.C[1, :]))

  emptycluster = trues(len)
  emptycluster[1] = false

  cl = zeros(Int, len)
  cl[1] = 1

  v = zeros(Int, len)
  v[1] = 6

  n1s = zeros(Float64, len, m)
  n1s[1, :] .= copy(vec(state.n1s[1, :]))

  unit = Vector{Int}[sum(state.R .== g) > 0 ? findall(state.R .== g) : [0] for g in 1:len]

  logpR = state.logpR
  logpC = copy(state.logpC)
  loglik = state.loglik
  logpp = state.logpp

  Kpax3.resizestate!(state, 5)

  @test state.R == R
  @test state.C == C
  @test state.emptycluster == emptycluster
  @test state.cl == cl
  @test state.k == k
  @test state.v == v
  @test state.n1s == n1s
  @test state.unit == unit
  @test state.logpR == logpR
  @test state.logpC == logpC
  @test state.loglik == loglik
  @test state.logpp == logpp

  # resizestate!(state, k, settings)
  # k < 2 * maxclust => len = maxclust
  settings = Kpax3.KSettings(ifile, ofile, maxclust=2, maxunit=1)

  priorR = Kpax3.EwensPitman(settings.α, settings.θ)
  priorC = Kpax3.AminoAcidPriorCol(data, settings.γ, settings.r)

  state = Kpax3.AminoAcidState(data, [1; 1; 1; 1; 1; 1], priorR, priorC, settings)

  len = 4

  R = copy(state.R)
  k = state.k

  C = zeros(UInt8, len, m)
  C[1, :] .= copy(vec(state.C[1, :]))

  emptycluster = trues(len)
  emptycluster[1] = false

  cl = zeros(Int, len)
  cl[1] = 1

  v = zeros(Int, len)
  v[1] = 6

  n1s = zeros(Float64, len, m)
  n1s[1, :] .= copy(vec(state.n1s[1, :]))

  unit = Vector{Int}[sum(state.R .== g) > 0 ? findall(state.R .== g) : [0] for g in 1:len]

  logpR = state.logpR
  logpC = copy(state.logpC)
  loglik = state.loglik
  logpp = state.logpp

  Kpax3.resizestate!(state, 3, settings)

  @test state.R == R
  @test state.C == C
  @test state.emptycluster == emptycluster
  @test state.cl == cl
  @test state.k == k
  @test state.v == v
  @test state.n1s == n1s
  @test state.unit == unit
  @test state.logpR == logpR
  @test state.logpC == logpC
  @test state.loglik == loglik
  @test state.logpp == logpp

  # resizestate!(state, k, settings)
  # k > 2 * maxclust => len = k
  settings = Kpax3.KSettings(ifile, ofile, maxclust=2, maxunit=1)

  priorR = Kpax3.EwensPitman(settings.α, settings.θ)
  priorC = Kpax3.AminoAcidPriorCol(data, settings.γ, settings.r)

  state = Kpax3.AminoAcidState(data, [1; 1; 1; 1; 1; 1], priorR, priorC, settings)

  len = 5

  R = copy(state.R)
  k = state.k

  C = zeros(UInt8, len, m)
  C[1, :] .= copy(vec(state.C[1, :]))

  emptycluster = trues(len)
  emptycluster[1] = false

  cl = zeros(Int, len)
  cl[1] = 1

  v = zeros(Int, len)
  v[1] = 6

  n1s = zeros(Float64, len, m)
  n1s[1, :] .= copy(vec(state.n1s[1, :]))

  unit = Vector{Int}[sum(state.R .== g) > 0 ? findall(state.R .== g) : [0] for g in 1:len]

  logpR = state.logpR
  logpC = copy(state.logpC)
  loglik = state.loglik
  logpp = state.logpp

  Kpax3.resizestate!(state, 5, settings)

  @test state.R == R
  @test state.C == C
  @test state.emptycluster == emptycluster
  @test state.cl == cl
  @test state.k == k
  @test state.v == v
  @test state.n1s == n1s
  @test state.unit == unit
  @test state.logpR == logpR
  @test state.logpC == logpC
  @test state.loglik == loglik
  @test state.logpp == logpp

  nothing
end

test_state_resizestate()

function test_state_copy_basic()
  ifile = "data/read_proper_aa.fasta"
  ofile = "../build/test"

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

  settings = Kpax3.KSettings(ifile, ofile, maxclust=1, maxunit=1)

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

  state1 = Kpax3.AminoAcidState(copy(R), copy(C), copy(emptycluster), copy(cl), k, copy(v), copy(n1s), deepcopy(unit), logpR, copy(logpC), loglik, logpp)
  state2 = Kpax3.copystate(state1)

  @test state2.R == R
  @test state2.C == C
  @test state2.emptycluster == emptycluster
  @test state2.cl == cl
  @test state2.k == k
  @test state2.v == v
  @test state2.n1s == n1s
  @test state2.unit == unit
  @test state2.logpR == logpR
  @test state2.logpC == logpC
  @test state2.loglik == loglik
  @test state2.logpp == logpp

  # objects should be copies, not references to state1 objects
  # change state1 objects and see if the copy changes as well
  state1.R = [1; 1; 1; 1; 2; 3]
  fill!(state1.C, UInt8(2))
  state1.emptycluster = [false; false; false; true; true]
  state1.cl = [1; 2; 3; 0; 0]
  state1.k = 3
  state1.v = [4; 1; 1; 0; 2]
  state1.n1s[1, :] .= vec(sum(float(data[:, state1.R .== 1]), dims=2))
  state1.n1s[2, :] .= vec(sum(float(data[:, state1.R .== 2]), dims=2))
  state1.n1s[3, :] .= vec(sum(float(data[:, state1.R .== 3]), dims=2))
  state1.unit[1] = [1; 2; 3; 4]
  state1.unit[2] = [5; 0]
  state1.unit[3] = [6]
  state1.logpR = Kpax3.logdPriorRow(n, state1.k, state1.v[1:state1.k], priorR)
  state1.logpC[1] = Kpax3.logpriorC(state1.C, state1.cl, state1.k, priorC)
  state1.logpC[2] = Kpax3.logcondpostC(state1.C, state1.cl, state1.k, state1.v, state1.n1s, priorC)
  state1.loglik = Kpax3.loglikelihood(state1.C, state1.cl, state1.k, state1.v, state1.n1s, priorC)
  state1.logpp = state1.logpR + state1.logpC[1] + state1.loglik

  @test state2.R == R
  @test state2.C == C
  @test state2.emptycluster == emptycluster
  @test state2.cl == cl
  @test state2.k == k
  @test state2.v == v
  @test state2.n1s == n1s
  @test state2.unit == unit
  @test state2.logpR == logpR
  @test state2.logpC == logpC
  @test state2.loglik == loglik
  @test state2.logpp == logpp

  nothing
end

test_state_copy_basic()

function test_state_copy_with_resize()
  ifile = "data/read_proper_aa.fasta"
  ofile = "../build/test"

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

  settings = Kpax3.KSettings(ifile, ofile, maxclust=1, maxunit=1)

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

  state1 = Kpax3.AminoAcidState(copy(R), copy(C), copy(emptycluster), copy(cl), k, copy(v), copy(n1s), deepcopy(unit), logpR, copy(logpC), loglik, logpp)

  settings = Kpax3.KSettings(ifile, ofile, maxclust=1, maxunit=1)

  state2 = Kpax3.AminoAcidState(data, [1; 1; 1; 1; 1; 1], priorR, priorC, settings)

  Kpax3.copystate!(state2, state1)

  l = state1.cl[1:state1.k]

  @test state2.R == state1.R
  @test state2.C[l, :] == state1.C[l, :]
  @test state2.emptycluster[l] == state1.emptycluster[l]
  @test state2.cl[1:state2.k] == state1.cl[1:state1.k]
  @test state2.k == state1.k
  @test state2.v[l] == state1.v[l]
  @test state2.n1s[l, :] == state1.n1s[l, :]
  for g in l
    @test state2.unit[g][1:state2.v[g]] == state1.unit[g][1:state1.v[g]]
  end
  @test state2.logpR == state1.logpR
  @test state2.logpC == state1.logpC
  @test state2.loglik == state1.loglik
  @test state2.logpp == state1.logpp

  state1.R = [1; 3; 3; 4; 4; 5]
  fill!(state1.C, UInt8(2))
  state1.emptycluster = [false; true; false; false; true; false]
  state1.cl = [1; 3; 4; 5; 0; 0]
  state1.k = 4
  state1.v = [1; 0; 2; 2; 1; 0]
  fill!(state1.n1s, 0.0)
  state1.n1s[1, :] .= vec(sum(float(data[:, state1.R .== 1]), dims=2))
  state1.n1s[3, :] .= vec(sum(float(data[:, state1.R .== 3]), dims=2))
  state1.n1s[4, :] .= vec(sum(float(data[:, state1.R .== 4]), dims=2))
  state1.n1s[5, :] .= vec(sum(float(data[:, state1.R .== 5]), dims=2))
  state1.unit[1] = [1; 0; 0; 0; 0; 0]
  state1.unit[2] = [0; 0; 0; 0; 0; 0]
  state1.unit[3] = [2; 3; 0; 0; 0; 0]
  state1.unit[4] = [4; 5; 0; 0; 0; 0]
  state1.unit[5] = [6; 0; 0; 0; 0; 0]
  state1.logpR = Kpax3.logdPriorRow(n, state1.k, state1.v[[1; 3; 4; 5]], priorR)
  state1.logpC[1] = Kpax3.logpriorC(state1.C, state1.cl, state1.k, priorC)
  state1.logpC[2] = Kpax3.logcondpostC(state1.C, state1.cl, state1.k, state1.v, state1.n1s, priorC)
  state1.loglik = Kpax3.loglikelihood(state1.C, state1.cl, state1.k, state1.v, state1.n1s, priorC)
  state1.logpp = state1.logpR + state1.logpC[1] + state1.loglik

  @test state2.R != state1.R
  @test state2.C[l, :] != state1.C[l, :]
  @test state2.emptycluster[l] != state1.emptycluster[l]
  @test state2.cl[1:state2.k] != state1.cl[1:state2.k]
  @test state2.k != state1.k
  @test state2.v[l] != state1.v[l]
  @test state2.n1s[l, :] != state1.n1s[l, :]
  for g in l
    @test state2.unit[g][1:state2.v[g]] != state1.unit[g][1:state1.v[g]]
  end
  @test state2.logpR != state1.logpR
  @test state2.logpC != state1.logpC
  @test state2.loglik != state1.loglik
  @test state2.logpp != state1.logpp

  nothing
end

test_state_copy_with_resize()

function test_state_copy_without_resize()
  ifile = "data/read_proper_aa.fasta"
  ofile = "../build/test"

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

  settings = Kpax3.KSettings(ifile, ofile, maxclust=1, maxunit=1)

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

  state1 = Kpax3.AminoAcidState(copy(R), copy(C), copy(emptycluster), copy(cl), k, copy(v), copy(n1s), deepcopy(unit), logpR, copy(logpC), loglik, logpp)

  settings = Kpax3.KSettings(ifile, ofile, maxclust=6, maxunit=6)
  state2 = Kpax3.AminoAcidState(data, [1; 1; 1; 1; 1; 1], priorR, priorC, settings)

  Kpax3.copystate!(state2, state1)

  l = state1.cl[1:state1.k]

  @test state2.R == state1.R
  @test state2.C[l, :] == state1.C[l, :]
  @test state2.emptycluster[l] == state1.emptycluster[l]
  @test state2.cl[1:state2.k] == state1.cl[1:state1.k]
  @test state2.k == state1.k
  @test state2.v[l] == state1.v[l]
  @test state2.n1s[l, :] == state1.n1s[l, :]
  for g in l
    @test state2.unit[g][1:state2.v[g]] == state1.unit[g][1:state1.v[g]]
  end
  @test state2.logpR == state1.logpR
  @test state2.logpC == state1.logpC
  @test state2.loglik == state1.loglik
  @test state2.logpp == state1.logpp

  state1.R = [1; 3; 3; 4; 4; 5]
  fill!(state1.C, UInt8(2))
  state1.emptycluster = [false; true; false; false; true; false]
  state1.cl = [1; 3; 4; 5; 0; 0]
  state1.k = 4
  state1.v = [1; 0; 2; 2; 1; 0]
  fill!(state1.n1s, 0.0)
  state1.n1s[1, :] .= vec(sum(float(data[:, state1.R .== 1]), dims=2))
  state1.n1s[3, :] .= vec(sum(float(data[:, state1.R .== 3]), dims=2))
  state1.n1s[4, :] .= vec(sum(float(data[:, state1.R .== 4]), dims=2))
  state1.n1s[5, :] .= vec(sum(float(data[:, state1.R .== 5]), dims=2))
  state1.unit[1] = [1; 0; 0; 0; 0; 0]
  state1.unit[2] = [0; 0; 0; 0; 0; 0]
  state1.unit[3] = [2; 3; 0; 0; 0; 0]
  state1.unit[4] = [4; 5; 0; 0; 0; 0]
  state1.unit[5] = [6; 0; 0; 0; 0; 0]
  state1.logpR = Kpax3.logdPriorRow(n, state1.k, state1.v[[1; 3; 4; 5]], priorR)
  state1.logpC[1] = Kpax3.logpriorC(state1.C, state1.cl, state1.k, priorC)
  state1.logpC[2] = Kpax3.logcondpostC(state1.C, state1.cl, state1.k, state1.v, state1.n1s, priorC)
  state1.loglik = Kpax3.loglikelihood(state1.C, state1.cl, state1.k, state1.v, state1.n1s, priorC)
  state1.logpp = state1.logpR + state1.logpC[1] + state1.loglik

  @test state2.R != state1.R
  @test state2.C[l, :] != state1.C[l, :]
  @test state2.emptycluster[l] != state1.emptycluster[l]
  @test state2.cl[1:state2.k] != state1.cl[1:state2.k]
  @test state2.k != state1.k
  @test state2.v[l] != state1.v[l]
  @test state2.n1s[l, :] != state1.n1s[l, :]
  for g in l
    @test state2.unit[g][1:state2.v[g]] != state1.unit[g][1:state1.v[g]]
  end
  @test state2.logpR != state1.logpR
  @test state2.logpC != state1.logpC
  @test state2.loglik != state1.loglik
  @test state2.logpp != state1.logpp

  nothing
end

test_state_copy_without_resize()

function test_state_update_with_resize()
  ifile = "data/read_proper_aa.fasta"
  ofile = "../build/test"

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

  settings = Kpax3.KSettings(ifile, ofile, maxclust=1, maxunit=1)

  priorR = Kpax3.EwensPitman(settings.α, settings.θ)
  priorC = Kpax3.AminoAcidPriorCol(data, settings.γ, settings.r)

  state1 = Kpax3.AminoAcidState(data, [1; 1; 1; 1; 2; 3], priorR, priorC, settings)
  state2 = Kpax3.AminoAcidState(data, [1; 1; 1; 1; 1; 1], priorR, priorC, settings)

  Kpax3.updatestate!(state2, data, [1; 1; 1; 1; 2; 3], priorR, priorC, settings)

  @test state2.R == state1.R
  @test state2.C == state1.C
  @test state2.emptycluster == state1.emptycluster
  @test state2.cl == state1.cl
  @test state2.k == state1.k
  @test state2.v == state1.v
  @test state2.n1s == state1.n1s
  @test state2.unit[1] == [1; 2; 3; 4; 5; 6]
  @test state2.unit[2] == [5]
  @test state2.unit[3] == [6]
  @test state2.logpR == state1.logpR
  @test state2.logpC == state1.logpC
  @test state2.loglik == state1.loglik
  @test state2.logpp == state1.logpp

  nothing
end

test_state_update_with_resize()

function test_state_update_without_resize()
  ifile = "data/read_proper_aa.fasta"
  ofile = "../build/test"

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

  settings = Kpax3.KSettings(ifile, ofile, maxclust=6, maxunit=6)

  priorR = Kpax3.EwensPitman(settings.α, settings.θ)
  priorC = Kpax3.AminoAcidPriorCol(data, settings.γ, settings.r)

  state1 = Kpax3.AminoAcidState(data, [1; 1; 1; 2; 2; 2], priorR, priorC, settings)
  state2 = Kpax3.AminoAcidState(data, [1; 1; 2; 2; 3; 3], priorR, priorC, settings)

  Kpax3.updatestate!(state2, data, [1; 1; 1; 2; 2; 2], priorR, priorC, settings)

  l = state1.cl[1:state1.k]

  @test state2.R == state1.R
  @test state2.C[l, :] == state1.C[l, :]
  @test state2.emptycluster == state1.emptycluster
  @test state2.cl[l] == state1.cl[l]
  @test state2.k == state1.k
  @test state2.v[l] == state1.v[l]
  @test state2.n1s[l, :] == state1.n1s[l, :]
  @test state2.unit[1] == [1; 2; 3; 0; 0; 0]
  @test state2.unit[2] == [4; 5; 6; 0; 0; 0]
  @test state2.unit[3] == [5; 6; 0; 0; 0; 0]
  @test state2.logpR == state1.logpR
  @test state2.logpC == state1.logpC
  @test state2.loglik == state1.loglik
  @test state2.logpp == state1.logpp

  nothing
end

test_state_update_without_resize()

function test_state_initializestate()
  ifile = "data/read_proper_aa.fasta"
  ofile = "../build/test"

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

  settings = Kpax3.KSettings(ifile, ofile, maxclust=6, maxunit=6)

  priorR = Kpax3.EwensPitman(settings.α, settings.θ)
  priorC = Kpax3.AminoAcidPriorCol(data, settings.γ, settings.r)

  D = zeros(Float64, n, n)
  for j in 1:(n - 1), i in (j + 1):n
    D[i, j] = D[j, i] = sum(data[:, j] .!= data[:, i]) / m
  end

  s = Kpax3.initializestate(data, D, 1:6, priorR, priorC, settings)

  @test isa(s.R, Vector{Int})
  @test all(s.R .> 0)

  t = Kpax3.AminoAcidState(data, s.R, priorR, priorC, settings)

  l = t.cl[1:t.k]

  @test s.R == t.R
  @test s.C == t.C
  @test s.emptycluster == t.emptycluster
  @test s.cl == t.cl
  @test s.k == t.k
  @test s.v == t.v
  @test s.n1s == t.n1s
  for g in l
    @test s.unit[g][1:s.v[g]] == t.unit[g][1:t.v[g]]
  end
  @test s.logpR == t.logpR
  @test s.logpC == t.logpC
  @test s.loglik == t.loglik

  @test isapprox(s.logpp, t.logpp, atol=ε)

  nothing
end

test_state_initializestate()
