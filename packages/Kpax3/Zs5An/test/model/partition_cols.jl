# This file is part of Kpax3. License is MIT.

#=
R = [1; 1; 2; 2; 3; 1]
k = length(unique(R))

priorR = Kpax3.EwensPitman(settings.α, settings.θ)
priorC = Kpax3.AminoAcidPriorCol(data, settings.γ, settings.r)

ss = UInt8[1; 2; 3]
obj = Kpax3.AminoAcidState(data, R, priorR, priorC, settings)

M = -Inf
for s1 in ss, s2 in ss, s3 in ss, s4 in ss
  S = [s1; s2; s3; s4]
  lp = Kpax3.logcondpostS(S, obj.cl, obj.k, obj.v, obj.n1s, priorC)

  if lp > M
    M = lp
  end
end

trueSp = zeros(Float64, 3, 4)
for s1 in ss, s2 in ss, s3 in ss, s4 in ss
  S = [s1; s2; s3; s4]
  lp = Kpax3.logcondpostS(S, obj.cl, obj.k, obj.v, obj.n1s, priorC)

  trueSp[s1, 1] += exp(lp - M)
  trueSp[s2, 2] += exp(lp - M)
  trueSp[s3, 3] += exp(lp - M)
  trueSp[s4, 4] += exp(lp - M)
end

trueSp = exp(M + log(trueSp))

for i in 1:12
  @printf("%.100f\n", trueSp[i])
end

Kpax3.rpostpartitioncols!(obj.C, obj.cl, obj.k, obj.v, obj.n1s, priorC);
obj.C[obj.cl[1:obj.k], :]

obj.C[obj.cl[1:obj.k], :] = Ctest1

p = exp(Kpax3.logcondpostC(obj.C, obj.cl, obj.k, obj.v, obj.n1s, priorC))
@printf("%.100f\n", p)
=#

function test_partition_cols_constructor()
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

  n1s = Float64[1; 5; 3; 3; 2; 2; 3; 3; 1; 3; 2; 1; 3; 2; 4; 2; 3; 3]

  r1 = 2.0
  r2 = 100.0

  A1 = zeros(Float64, 4, m)
  A1[1, :] .= (r1 + 1.0) .* (n1s .+ 0.5) ./ (n + 1)
  A1[2, :] .= 1.0
  A1[3, :] .= 1.0
  A1[4, :] .= r1

  B1 = zeros(Float64, 4, m)
  B1[1, :] .= (r1 + 1.0) .- A1[1, :]
  B1[2, :] .= 1.0
  B1[3, :] .= r1
  B1[4, :] .= 1.0

  A2 = zeros(Float64, 4, m)
  A2[1, :] .= n1s .+ 0.5
  A2[2, :] .= 1.0
  A2[3, :] .= 1.0
  A2[4, :] .= r2

  B2 = zeros(Float64, 4, m)
  B2[1, :] .= n .- n1s .+ 0.5
  B2[2, :] .= 1.0
  B2[3, :] .= r2
  B2[4, :] .= 1.0

  for k in 1:n
    for γ in ([1.0; 0.0; 0.0], [0.0; 1.0; 0.0], [0.0; 0.0; 1.0], [0.4; 0.3; 0.3], [0.5; 0.3; 0.2], [0.7; 0.2; 0.1], [0.1; 0.1; 0.1], [0.3; 0.1; 0.1], [0.0; 0.2; 0.1])
      x1 = Kpax3.AminoAcidPriorCol(data, γ, r1)
      x2 = Kpax3.AminoAcidPriorCol(data, γ, r2)

      @test isapprox(x1.logγ[1], log(γ[1] / sum(γ)), atol=ε)
      @test isapprox(x2.logγ[2], log(γ[2] / sum(γ)), atol=ε)
      @test isapprox(x2.logγ[3], log(γ[3] / sum(γ)), atol=ε)

      @test isapprox(x1.logω[k][1], log(1.0 - 1.0 / k), atol=ε)
      @test isapprox(x2.logω[k][2], log(1.0 / k), atol=ε)

      for b in 1:m, s in 1:4
        @test isapprox(x1.A[s, b], A1[s, b], atol=ε)
        @test isapprox(x1.B[s, b], B1[s, b], atol=ε)

        @test isapprox(x2.A[s, b], A2[s, b], atol=ε)
        @test isapprox(x2.B[s, b], B2[s, b], atol=ε)
      end
    end
  end

  nothing
end

test_partition_cols_constructor()

function test_partition_cols_functions()
  ifile = "data/read_proper_aa.fasta"
  ofile = "../build/test"

  data = UInt8[1 1 0 0 1 1;
               0 0 1 1 0 0;
               1 1 0 0 0 1;
               1 0 0 0 1 1]

  (m, n) = size(data)

  settings = Kpax3.KSettings(ifile, ofile, maxclust=6, maxunit=1)

  R = [1; 1; 2; 2; 3; 1]
  k = length(unique(R))

  priorR = Kpax3.EwensPitman(settings.α, settings.θ)
  priorC = Kpax3.AminoAcidPriorCol(data, settings.γ, settings.r)

  state = Kpax3.AminoAcidState(data, R, priorR, priorC, settings)

  C = zeros(UInt8, settings.maxclust, m)

  cs = (UInt8[1; 1; 1], UInt8[2; 2; 2], UInt8[3; 3; 3], UInt8[3; 3; 4], UInt8[3; 4; 3], UInt8[4; 3; 3], UInt8[3; 4; 4], UInt8[4; 3; 4], UInt8[4; 4; 3], UInt8[4; 4; 4])

  logp1 = zeros(Float64, (2 + 2^k)^m)
  logp2 = zeros(Float64, (2 + 2^k)^m)
  logp3 = zeros(Float64, (2 + 2^k)^m)

  l = 0

  for c1 in cs, c2 in cs, c3 in cs, c4 in cs
    l += 1

    tmp = hcat(c1, c2, c3, c4)

    state.C[state.cl[1], :] = C[1, :] = tmp[1, :]
    state.C[state.cl[2], :] = C[2, :] = tmp[2, :]
    state.C[state.cl[3], :] = C[3, :] = tmp[3, :]

    logp1[l] = Kpax3.logpriorC(state.C, state.cl, k, priorC)
    logp2[l] = Kpax3.logpriorC(C, k, priorC)
    logp3[l] = Kpax3.logcondpostC(state.C, state.cl, k, state.v, state.n1s, priorC)
  end

  M = maximum(logp1)
  p1 = exp(M + log(sum(exp.(logp1 .- M))))

  M = maximum(logp2)
  p2 = exp(M + log(sum(exp.(logp2 .- M))))

  M = maximum(logp3)
  p3 = exp(M + log(sum(exp.(logp3 .- M))))

  @test isapprox(p1, 1.0, atol=ε)
  @test isapprox(p2, 1.0, atol=ε)
  @test isapprox(p3, 1.0, atol=ε)

  ss = UInt8[1; 2; 3]
  logp4 = zeros(Float64, 3^m)
  l = 0

  for s1 in ss, s2 in ss, s3 in ss, s4 in ss
    l += 1
    S = [s1; s2; s3; s4]
    logp4[l] = Kpax3.logcondpostS(S, state.cl, k, state.v, state.n1s, priorC)
  end

  M = maximum(logp4)
  p4 = exp(M + log(sum(exp.(logp4 .- M))))

  @test isapprox(p4, 1.0, atol=ε)

  nothing
end

test_partition_cols_functions()

function test_partition_cols_simulations()
  ifile = "data/read_proper_aa.fasta"
  ofile = "../build/test"

  data = UInt8[1 1 0 0 1 1;
               0 0 1 1 0 0;
               1 1 0 0 0 1;
               1 0 0 0 1 1]

  (m, n) = size(data)

  settings = Kpax3.KSettings(ifile, ofile, maxclust=1, maxunit=1)

  priorR = Kpax3.EwensPitman(settings.α, settings.θ)
  priorC = Kpax3.AminoAcidPriorCol(data, settings.γ, settings.r)

  state = Kpax3.AminoAcidState(data, [1; 1; 2; 2; 3; 1], priorR, priorC, settings)

  N = 1000000

  Sp = zeros(Float64, 3, m)
  Cp = zero(Float64)
  Ctest = UInt8[2 1 4 1; 2 1 3 1; 2 1 3 1]

  trueSp = hcat([0.514127006003589515081841909704962745308876037597656250000,
                 0.389747596850238686716494385109399445354938507080078125000,
                 0.096125397146171798201663705185637809336185455322265625000],
                [0.469929717191958307154209251166321337223052978515625000000,
                 0.356242671218090556362056986472452990710735321044921875000,
                 0.173827611589951080972582531103398650884628295898437500000],
                [0.400605930740164040138040491001447662711143493652343750000,
                 0.402853999936236717438475807284703478217124938964843750000,
                 0.196540069323599214667908086084935348480939865112304687500],
                [0.653732577496086042501133306359406560659408569335937500000,
                 0.344352962631683023886353112175129354000091552734375000000,
                 0.001914459872230926673619677558235707692801952362060546875])

  trueCp = 0.023444249569984754177909280770109035074710845947265625

  for t in 1:N
    Kpax3.rpostpartitioncols!(state.C, state.cl, state.k, state.v, state.n1s, priorC)

    for b in 1:m
      if state.C[state.cl[1], b] == 0x01
        @test state.C[state.cl[2], b] == 0x01
        @test state.C[state.cl[3], b] == 0x01

        Sp[1, b] += 1.0
      elseif state.C[state.cl[1], b] == 0x02
        @test state.C[state.cl[2], b] == 0x02
        @test state.C[state.cl[3], b] == 0x02

        Sp[2, b] += 1.0
      else
        Sp[3, b] += 1.0
      end
    end

    if all(state.C[state.cl[1:state.k], :] .== Ctest)
      Cp += 1.0
    end
  end

  Sp /= N

  @test isapprox(Sp, trueSp, rtol=0.01)

  Cp /= N

  @test isapprox(Cp, trueCp, atol=0.005)

  nothing
end

test_partition_cols_simulations()
