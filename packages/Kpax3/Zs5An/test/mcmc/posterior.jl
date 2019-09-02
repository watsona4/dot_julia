# This file is part of Kpax3. License is MIT.

# parameters to test are
# R = [1; 1; 2; 2; 3; 2]
# S = [2; 3; 1; 2]
# C = [2 3 1 2;
#      2 4 1 2;
#      2 3 1 2]

#=
# compute log(normalization constant) as accurate as possible
include("data/partitions.jl")

function Kpax3.computelogp(b::Int,
                     c::Vector{UInt8},
                     n1s::Matrix{Float64},
                     priorC::Kpax3.AminoAcidPriorCol)
  k = size(n1s, 1)
  logp = 0.0

  if c[1] == UInt8(1)
    logp = priorC.logγ[1]

    for g in 1:k
      logp += Kpax3.logmarglik(n1s[g, b], v[g], priorC.A[1, b], priorC.B[1, b])
    end
  elseif c1[1] == UInt8(2)
    logp = priorC.logγ[2]

    for g in 1:k
      logp += Kpax3.logmarglik(n1s[g, b], v[g], priorC.A[2, b], priorC.B[2, b])
    end
  else
    logp = priorC.logγ[3]

    for g in 1:k
      logp += priorC.logω[k][c[g] - 2] + Kpax3.logmarglik(n1s[g, b], v[g], priorC.A[c[g], b], priorC.B[c[g], b])
    end
  end

  logp
end

function addvalue!(b::Int,
                   c::Vector{UInt8},
                   value::Float64,
                   S::Matrix{Float64})
  if c[1] == UInt8(1)
    S[1, b] += value
  elseif c[1] == UInt8(2)
    S[2, b] += value
  else
    S[3, b] += value
  end

  nothing
end

function Kpax3.computelognormconst(ck,
                             k::Int,
                             lumpp::Float64,
                             data::Matrix{UInt8},
                             po::TestPartition,
                             γ::Vector{Float64},
                             r::Float64,
                             priorR::Kpax3.PriorRowPartition)
  (m, n) = size(data)

  priorC = Kpax3.AminoAcidPriorCol(data, γ, r)

  st = po.index[po.k .== k][1]
  en = any(po.k .== k + 1) ? po.index[po.k .== k + 1][1] - 1 : st

  R = zeros(Int, n)
  v = zeros(Float64, k)
  n1s = zeros(Float64, k, m)

  M = -Inf

  g = 0

  p = 0.0
  logprR = 0.0
  logpost = 0.0
  logp = zeros(Float64, m)

  for l in st:en
    fill!(R, 0)
    fill!(v, 0)
    fill!(n1s, 0.0)
    fill!(logp, 0.0)

    for a in 1:n
      g = po.partition[a, l]

      R[a] = g
      v[g] += 1

      for b in 1:m
        n1s[g, b] += float(data[b, a])
      end
    end

    logprR = Kpax3.logdPriorRow(R, priorR)

    for c1 in ck, c2 in ck, c3 in ck, c4 in ck
      logp[1] += Kpax3.computelogp(1, c1, n1s, priorC)
      logp[2] += Kpax3.computelogp(2, c2, n1s, priorC)
      logp[3] += Kpax3.computelogp(3, c3, n1s, priorC)
      logp[4] += Kpax3.computelogp(4, c4, n1s, priorC)

      logpost = logprR + logp[1] + logp[2] + logp[3] + logp[4]

      if logpost > M
        M = logpost
      end

      p += exp(logpost - lumpp)
    end
  end

  (M, p)
end

function lognormconst(cs,
                      data::Matrix{UInt8},
                      po::TestPartition,
                      γ::Vector{Float64},
                      r::Float64,
                      priorR::Kpax3.PriorRowPartition)
  # log unnormalized maximum posterior probability
  lumpp = -Inf

  println("Computing 'lumpp'...")
  for k in 1:size(data, 2)
    println("k = ", k)
    t1, t2 = Kpax3.computelognormconst(cs[k], k, 0.0, data, po, γ, r, priorR)

    if t1 > lumpp
      lumpp = t1
    end
  end
  println("Done.")

  # now that we know the maximum value, we can compute the logarithm of the
  # normalization constant
  z = 0.0

  println("Computing 'z'...")
  for k in 1:size(data, 2)
    println("k = ", k)
    t1, t2 = Kpax3.computelognormconst(cs[k], k, lumpp, data, po, γ, r, priorR)
    z += t2
  end
  println("Done.")

  (log(z), lumpp)
end

function computeProbs(cs,
                      lz::Float64,
                      lumpp::Float64,
                      data::Matrix{UInt8},
                      po::TestPartition,
                      γ::Vector{Float64},
                      r::Float64,
                      priorR::Kpax3.PriorRowPartition)
  (m, n) = size(data)

  P = zeros(Float64, div(n * (n - 1), 2))
  S = zeros(Float64, 3, m)
  K = zeros(Float64, n)

  u = falses(div(n * (n - 1), 2))

  R = zeros(Int, n)

  logprR = 0.0
  logpost = 0.0
  logp = zeros(Float64, m)

  println("Computing probabilities...")
  for k in 1:(n - 1)
    println("k = ", k)

    priorC = Kpax3.AminoAcidPriorCol(data, γ, r)

    st = po.index[po.k .== k][1]
    en = po.index[po.k .== k + 1][1] - 1

    v = zeros(Float64, k)
    n1s = zeros(Float64, k, m)

    for l in st:en
      fill!(R, 0)
      fill!(v, 0)
      fill!(n1s, 0.0)
      fill!(logp, 0.0)

      for a in 1:n
        g = po.partition[a, l]

        R[a] = g
        v[g] += 1

        for b in 1:m
          n1s[g, b] += float(data[b, a])
        end
      end

      logprR = Kpax3.logdPriorRow(R, priorR)

      idx = 1
      for i in 1:(n - 1)
        for j in (i + 1):n
          u[idx] = (R[i] == R[j])
          idx += 1
        end
      end

      for c1 in cs[k], c2 in cs[k], c3 in cs[k], c4 in cs[k]
        logp[1] += Kpax3.computelogp(1, c1, n1s, priorC)
        logp[2] += Kpax3.computelogp(2, c2, n1s, priorC)
        logp[3] += Kpax3.computelogp(3, c3, n1s, priorC)
        logp[4] += Kpax3.computelogp(4, c4, n1s, priorC)

        tmp = exp(logpost - lumpp)

        P[u] += tmp
        K[k] += tmp

        addvalue!(1, c1, tmp, S)
        addvalue!(2, c2, tmp, S)
        addvalue!(3, c3, tmp, S)
        addvalue!(4, c4, tmp, S)
      end
    end
  end

  # no units are in the same cluster
  k = n
  println("k = ", k)

  priorC = Kpax3.AminoAcidPriorCol(data, γ, r)

  v = ones(Float64, k)
  n1s = zeros(Float64, k, m)

  fill!(R, 0)
  fill!(logp, 0.0)

  for a in 1:n
    R[a] = a

    for b in 1:m
      n1s[a, b] = float(data[b, a])
    end
  end

  logprR = Kpax3.logdPriorRow(R, priorR)

  idx = 1
  for i in 1:(n - 1)
    for j in (i + 1):n
      u[idx] = (R[i] == R[j])
      idx += 1
    end
  end

  for c1 in cs[k], c2 in cs[k], c3 in cs[k], c4 in cs[k]
    logp[1] += Kpax3.computelogp(1, c1, n1s, priorC)
    logp[2] += Kpax3.computelogp(2, c2, n1s, priorC)
    logp[3] += Kpax3.computelogp(3, c3, n1s, priorC)
    logp[4] += Kpax3.computelogp(4, c4, n1s, priorC)

    tmp = exp(logpost - lumpp)

    P[u] += tmp
    K[k] += tmp

    addvalue!(1, c1, tmp, S)
    addvalue!(2, c2, tmp, S)
    addvalue!(3, c3, tmp, S)
    addvalue!(4, c4, tmp, S)
  end
  println("Done.")

  (exp(log(P) - lz), exp(log(S) - lz), exp(log(K) - lz))
end

settings = Kpax3.KSettings(ifile, ofile, alpha=α, theta=θ)

x = Kpax3.AminoAcidData(settings)

priorR = Kpax3.EwensPitman(settings.α, settings.θ)
po = TestPartition(size(x.data, 2))
cs = ((UInt8[1], UInt8[2], UInt8[3], UInt8[4]),
      (UInt8[1; 1], UInt8[2; 2], UInt8[3; 3], UInt8[3; 4], UInt8[4; 3],
       UInt8[4; 4]),
      (UInt8[1; 1; 1], UInt8[2; 2; 2], UInt8[3; 3; 3], UInt8[3; 3; 4],
       UInt8[3; 4; 3], UInt8[4; 3; 3], UInt8[3; 4; 4], UInt8[4; 3; 4],
       UInt8[4; 4; 3], UInt8[4; 4; 4]),
      (UInt8[1; 1; 1; 1], UInt8[2; 2; 2; 2], UInt8[3; 3; 3; 3],
       UInt8[3; 3; 3; 4], UInt8[3; 3; 4; 3], UInt8[3; 4; 3; 3],
       UInt8[4; 3; 3; 3], UInt8[3; 3; 4; 4], UInt8[3; 4; 3; 4],
       UInt8[3; 4; 4; 3], UInt8[4; 3; 3; 4], UInt8[4; 3; 4; 3],
       UInt8[4; 4; 3; 3], UInt8[3; 4; 4; 4], UInt8[4; 3; 4; 4],
       UInt8[4; 4; 3; 4], UInt8[4; 4; 4; 3], UInt8[4; 4; 4; 4]),
      (UInt8[1; 1; 1; 1; 1], UInt8[2; 2; 2; 2; 2], UInt8[3; 3; 3; 3; 3],
       UInt8[3; 3; 3; 3; 4], UInt8[3; 3; 3; 4; 3], UInt8[3; 3; 4; 3; 3],
       UInt8[3; 4; 3; 3; 3], UInt8[4; 3; 3; 3; 3], UInt8[3; 3; 3; 4; 4],
       UInt8[3; 3; 4; 3; 4], UInt8[3; 3; 4; 4; 3], UInt8[3; 4; 3; 3; 4],
       UInt8[3; 4; 3; 4; 3], UInt8[3; 4; 4; 3; 3], UInt8[4; 3; 3; 3; 4],
       UInt8[4; 3; 3; 4; 3], UInt8[4; 3; 4; 3; 3], UInt8[4; 4; 3; 3; 3],
       UInt8[3; 3; 4; 4; 4], UInt8[3; 4; 3; 4; 4], UInt8[3; 4; 4; 3; 4],
       UInt8[3; 4; 4; 4; 3], UInt8[4; 3; 3; 4; 4], UInt8[4; 3; 4; 3; 4],
       UInt8[4; 4; 3; 3; 4], UInt8[4; 3; 4; 4; 3], UInt8[4; 4; 3; 4; 3],
       UInt8[4; 4; 4; 3; 3], UInt8[3; 4; 4; 4; 4], UInt8[4; 3; 4; 4; 4],
       UInt8[4; 4; 3; 4; 4], UInt8[4; 4; 4; 3; 4], UInt8[4; 4; 4; 4; 3],
       UInt8[4; 4; 4; 4; 4]),
      (UInt8[1; 1; 1; 1; 1; 1], UInt8[2; 2; 2; 2; 2; 2],
       UInt8[3; 3; 3; 3; 3; 3], UInt8[3; 3; 3; 3; 3; 4],
       UInt8[3; 3; 3; 3; 4; 3], UInt8[3; 3; 3; 4; 3; 3],
       UInt8[3; 3; 4; 3; 3; 3], UInt8[3; 4; 3; 3; 3; 3],
       UInt8[4; 3; 3; 3; 3; 3], UInt8[3; 3; 3; 3; 4; 4],
       UInt8[3; 3; 3; 4; 3; 4], UInt8[3; 3; 3; 4; 4; 3],
       UInt8[3; 3; 4; 3; 3; 4], UInt8[3; 3; 4; 3; 4; 3],
       UInt8[3; 3; 4; 4; 3; 3], UInt8[3; 4; 3; 3; 3; 4],
       UInt8[3; 4; 3; 3; 4; 3], UInt8[3; 4; 3; 4; 3; 3],
       UInt8[3; 4; 4; 3; 3; 3], UInt8[4; 3; 3; 3; 3; 4],
       UInt8[4; 3; 3; 3; 4; 3], UInt8[4; 3; 3; 4; 3; 3],
       UInt8[4; 3; 4; 3; 3; 3], UInt8[4; 4; 3; 3; 3; 3],
       UInt8[3; 3; 3; 4; 4; 4], UInt8[3; 3; 4; 3; 4; 4],
       UInt8[3; 3; 4; 4; 3; 4], UInt8[3; 3; 4; 4; 4; 3],
       UInt8[3; 4; 3; 3; 4; 4], UInt8[3; 4; 3; 4; 3; 4],
       UInt8[3; 4; 4; 3; 3; 4], UInt8[3; 4; 3; 4; 4; 3],
       UInt8[3; 4; 4; 3; 4; 3], UInt8[3; 4; 4; 4; 3; 3],
       UInt8[4; 3; 3; 3; 4; 4], UInt8[4; 3; 3; 4; 3; 4],
       UInt8[4; 3; 4; 3; 3; 4], UInt8[4; 4; 3; 3; 3; 4],
       UInt8[4; 3; 3; 4; 4; 3], UInt8[4; 3; 4; 3; 4; 3],
       UInt8[4; 4; 3; 3; 4; 3], UInt8[4; 3; 4; 4; 3; 3],
       UInt8[4; 4; 3; 4; 3; 3], UInt8[4; 4; 4; 3; 3; 3],
       UInt8[3; 3; 4; 4; 4; 4], UInt8[3; 4; 3; 4; 4; 4],
       UInt8[3; 4; 4; 3; 4; 4], UInt8[3; 4; 4; 4; 3; 4],
       UInt8[3; 4; 4; 4; 4; 3], UInt8[4; 3; 3; 4; 4; 4],
       UInt8[4; 3; 4; 3; 4; 4], UInt8[4; 3; 4; 4; 3; 4],
       UInt8[4; 3; 4; 4; 4; 3], UInt8[4; 4; 3; 3; 4; 4],
       UInt8[4; 4; 3; 4; 3; 4], UInt8[4; 4; 3; 4; 4; 3],
       UInt8[4; 4; 4; 3; 3; 4], UInt8[4; 4; 4; 3; 4; 3],
       UInt8[4; 4; 4; 4; 3; 3], UInt8[3; 4; 4; 4; 4; 4],
       UInt8[4; 3; 4; 4; 4; 4], UInt8[4; 4; 3; 4; 4; 4],
       UInt8[4; 4; 4; 3; 4; 4], UInt8[4; 4; 4; 4; 3; 4],
       UInt8[4; 4; 4; 4; 4; 3], UInt8[4; 4; 4; 4; 4; 4]))

# lmpp = lumpp - lc = lumpp - lumpp - lz = - lz
# lc + lmpp = lumpp + lz - lz = lumpp
lz, lumpp = lognormconst(cs, x.data, po, settings.γ, settings.r, priorR)
probs = computeProbs(cs, lz, lumpp, x.data, po, settings.γ, settings.r, priorR)

@printf("%.100f\n", lz)
@printf("%.100f\n", lumpp)
@printf("%.100f\n", lumpp + lz)

for i in 1:6
  @printf("%.100f\n", probs[3][i])
end

for i in 1:15
  @printf("%.100f\n", probs[1][i])
end

for i in 1:12
  @printf("%.100f\n", probs[2][i])
end

# EwensPitmanPAUT
# lz = 2.82383600433172521348978989408351480960845947265625
# lumpp = -20.077619086471660381221226998604834079742431640625
# lc = lumpp + lz = -17.253783082139936055909856804646551609039306640625

# EwensPitmanPAZT
# lz = 3.718733440312136817595956017612479627132415771484375
# lumpp = -20.701675744062715267546082031913101673126220703125
# lc = lumpp + lz = -16.982942303750579782217755564488470554351806640625

# EwensPitmanZAPT
# lz = 4.09068229126453619670655825757421553134918212890625
# lumpp = -21.0913924952027400649967603385448455810546875
# lc = lumpp + lz = -17.00071020393820475646862178109586238861083984375

# EwensPitmanNAPT
# lz = 5.15291171975398309967886234517209231853485107421875
# lumpp = -21.99795555234826593959951424039900302886962890625
# lc = lumpp + lz = -16.845043832594281951742232195101678371429443359375
=#

function test_mcmc_algorithm()
  ifile = "data/mcmc_6.fasta"
  ofile = "../build/mcmc_6"

  partition = "data/mcmc_6.csv"

  x = Kpax3.AminoAcidData(Kpax3.KSettings(ifile, ofile))

  n = 6

  # EwensPitmanZAPT
  α = 0.0
  θ = 1.0

  settings = Kpax3.KSettings(ifile, ofile, maxclust=1, maxunit=1, alpha=α, theta=θ, op=[0.6; 0.2; 0.2])

  trueProbK = [0.0572011678382854799052026351091626565903425216674804687500000;
               0.3147244396041969372035396190767642110586166381835937500000000;
               0.3980266432259659814540952993411337956786155700683593750000000;
               0.1895011450641402861450046657409984618425369262695312500000000;
               0.0378534754499949971373595758450392168015241622924804687500000;
               0.0026931288174161633307279739568684817641042172908782958984375]

  tmp = [0.5647226958512603367523752240231260657310485839843750000;
         0.3859601712857648747601047034549992531538009643554687500;
         0.3859601712857648747601047034549992531538009643554687500;
         0.3877266490089570361021742428420111536979675292968750000;
         0.2495816768360757109679326504192431457340717315673828125;
         0.3859601712857648747601047034549992531538009643554687500;
         0.3859601712857648747601047034549992531538009643554687500;
         0.3877266490089570361021742428420111536979675292968750000;
         0.2495816768360757109679326504192431457340717315673828125;
         0.5647226958512601147077702989918179810047149658203125000;
         0.2495816768360775983470745131853618659079074859619140625;
         0.3877266490089560369014520802011247724294662475585937500;
         0.2495816768360764881240498880288214422762393951416015625;
         0.3877266490089572026356279366154922172427177429199218750;
         0.3775410735825202035442771375528536736965179443359375000]

  trueProbP = ones(Float64, n, n)
  idx = 0
  for j in 1:(n - 1), i in (j + 1):n
    idx += 1
    trueProbP[i, j] = trueProbP[j, i] = tmp[idx]
  end

  trueProbS = permutedims(
    reshape([0.6466162109955354564405638484458904713392257690429688;
             0.6466162109955360115520761610241606831550598144531250;
             0.6854223966792249989055108017055317759513854980468750;
             0.6810176138774772791606437749578617513179779052734375;
             0.3217860669917309568432983724051155149936676025390625;
             0.3217860669917303462206348285690182819962501525878906;
             0.2886555906155557904568809135525953024625778198242188;
             0.2863666389656327471158192565781064331531524658203125;
             0.0315977220123564370157787095649837283417582511901856;
             0.0315977220123591293066134255695942556485533714294434;
             0.0259220127048742574049633446975349215790629386901856;
             0.0326157471566144094299311007034702925011515617370606],
            (4, 3)))

  Kpax3.kpax3mcmc(x, partition, settings)

  (k, estimK) = Kpax3.readposteriork(settings.ofile)
  (id, estimP) = Kpax3.readposteriorP(settings.ofile)
  (site, aa, freq, estimS) = Kpax3.readposteriorC(settings.ofile)

  @test isapprox(estimK, trueProbK, rtol=0.02)
  @test isapprox(estimP, trueProbP, rtol=0.02)
  @test isapprox(estimS, trueProbS, rtol=0.02)

  # EwensPitmanPAUT
  α = 0.5
  θ = -0.25

  settings = Kpax3.KSettings(ifile, ofile, maxclust=1, maxunit=1, alpha=α, theta=θ, op=[0.6; 0.2; 0.2])

  trueProbK = [0.20304357310850917883726651780307292938232421875000000000;
               0.21850248716493331224697271863988135010004043579101562500;
               0.23654721412654236556427633786370279267430305480957031250;
               0.19408622743422676570901330705964937806129455566406250000;
               0.11197185302918269411698304338642628863453865051269531250;
               0.03584864513660558638097342054606997407972812652587890625]

  tmp = [0.570577011488977547948309165803948417305946350097656250;
         0.458274033588720208776123854477191343903541564941406250;
         0.458274033588720208776123854477191343903541564941406250;
         0.441580861997908746818808367606834508478641510009765625;
         0.356836131052323146661819919245317578315734863281250000;
         0.458274033588720208776123854477191343903541564941406250;
         0.458274033588720208776123854477191343903541564941406250;
         0.441580861997908746818808367606834508478641510009765625
         0.356836131052323146661819919245317578315734863281250000;
         0.570577011488982877018827366555342450737953186035156250;
         0.356836131052323146661819919245317578315734863281250000;
         0.441580861997908746818808367606834508478641510009765625;
         0.356836131052323146661819919245317578315734863281250000;
         0.441580861997908746818808367606834508478641510009765625;
         0.425947160536098878846900106509565375745296478271484375]

  trueProbP = ones(Float64, n, n)
  idx = 0
  for j in 1:(n - 1), i in (j + 1):n
    idx += 1
    trueProbP[i, j] = trueProbP[j, i] = tmp[idx]
  end

  trueProbS = permutedims(
    reshape([0.6628554623025003644798403001914266496896743774414063;
             0.6628554623024998093683279876131564378738403320312500;
             0.6958954347146397712009502356522716581821441650390625;
             0.6907786000474358534262364628375507891178131103515625;
             0.3161542446605755674049476056097773835062980651855469;
             0.3161542446605746792265279054845450446009635925292969;
             0.2858092016103817578631662854604655876755714416503907;
             0.2834957069790527972585891802737023681402206420898438;
             0.0209902930365564316383952814248914364725351333618164;
             0.0209902930365640644216895793761068489402532577514648;
             0.0182953636746360850939829845174244837835431098937988;
             0.0257256929731574761344159441023293766193091869354248],
            (4, 3)))

  Kpax3.kpax3mcmc(x, partition, settings)

  (k, estimK) = Kpax3.readposteriork(settings.ofile)
  (id, estimP) = Kpax3.readposteriorP(settings.ofile)
  (site, aa, freq, estimS) = Kpax3.readposteriorC(settings.ofile)

  @test isapprox(estimK, trueProbK, rtol=0.02)
  @test isapprox(estimP, trueProbP, rtol=0.02)
  @test isapprox(estimS, trueProbS, rtol=0.02)

  # EwensPitmanPAZT
  α = 0.5
  θ = 0.0

  settings = Kpax3.KSettings(ifile, ofile, maxclust=1, maxunit=1, alpha=α, theta=θ, op=[0.6; 0.2; 0.2])

  trueProbK = [0.08297365650265563219445397180606960318982601165771484375;
               0.17858186829001693185503540917125064879655838012695312500;
               0.25777307456537906782401137206761632114648818969726562500;
               0.25380237308441272459091919699858408421277999877929687500;
               0.16734077362357668850023628692724741995334625244140625000;
               0.05952825393395902442428280210151569917798042297363281250]

  tmp = [0.4594673179563065201769234136008890345692634582519531250;
         0.3358129241361126893217203814856475219130516052246093750;
         0.3358129241361126893217203814856475219130516052246093750;
         0.3205116334957199830668628237617667764425277709960937500;
         0.2303208685969153901584860477669280953705310821533203125;
         0.3358129241361126893217203814856475219130516052246093750;
         0.3358129241361126893217203814856475219130516052246093750;
         0.3205116334957199830668628237617667764425277709960937500;
         0.2303208685969170277374473698728252202272415161132812500;
         0.4594673179563261156133080476138275116682052612304687500;
         0.2303208685969153068917592008801875635981559753417968750;
         0.3205116334957179846654184984799940139055252075195312500;
         0.2303208685969174440710816043065278790891170501708984375;
         0.3205116334957179846654184984799940139055252075195312500;
         0.3050339698727991821769478519854601472616195678710937500]

  trueProbP = ones(Float64, n, n)
  idx = 0
  for j in 1:(n - 1), i in (j + 1):n
    idx += 1
    trueProbP[i, j] = trueProbP[j, i] = tmp[idx]
  end

  trueProbS = permutedims(
    reshape([0.6487705348032424268467366346158087253570556640625000;
             0.6487705348032450913819957349915057420730590820312500;
             0.6895045716381241751591346655914094299077987670898438;
             0.6820507372914499377714037109399214386940002441406250;
             0.3276120832340845279162522274418734014034271240234375;
             0.3276120832340849720054620775044895708560943603515625;
             0.2910537694838980504741243748867418617010116577148438;
             0.2876286629947675255181138709303922951221466064453125;
             0.0236173819628183144503363877220181166194379329681397;
             0.0236173819628183456753589553045458160340785980224609;
             0.0194416588781203998614888206475370679982006549835205;
             0.0303205997137780264294448784312407951802015304565430],
            (4, 3)))

  Kpax3.kpax3mcmc(x, partition, settings)

  (k, estimK) = Kpax3.readposteriork(settings.ofile)
  (id, estimP) = Kpax3.readposteriorP(settings.ofile)
  (site, aa, freq, estimS) = Kpax3.readposteriorC(settings.ofile)

  @test isapprox(estimK, trueProbK, rtol=0.02)
  @test isapprox(estimP, trueProbP, rtol=0.02)
  @test isapprox(estimS, trueProbS, rtol=0.02)

  # EwensPitmanNAPT
  α = -1
  θ = 4

  settings = Kpax3.KSettings(ifile, ofile, maxclust=1, maxunit=1, alpha=α, theta=θ, op=[0.6; 0.2; 0.2])

  trueProbK = [0.013987232861628222380101504995764116756618022918701171875;
               0.277957780373217555602849415663513354957103729248046875000;
               0.542335567963948439462740225280867889523506164550781250000;
               0.165719418801206025415595490812847856432199478149414062500]

  tmp = [0.5514954001719989395979837354389019310474395751953125000;
         0.3318939556633083709513698522641789168119430541992187500;
         0.3318939556633083709513698522641789168119430541992187500;
         0.3588148423035991685381418392353225499391555786132812500;
         0.1920174063238060946368079839885467663407325744628906250;
         0.3318939556633083709513698522641789168119430541992187500;
         0.3318939556633083709513698522641789168119430541992187500;
         0.3588148423035966150251852013752795755863189697265625000;
         0.1920174063238067885261983747113845311105251312255859375;
         0.5514954001719960530181197100318968296051025390625000000;
         0.1920174063238073713932863029185682535171508789062500000;
         0.3588148423035962819582778138283174484968185424804687500;
         0.1920174063238073713932863029185682535171508789062500000;
         0.3588148423035962819582778138283174484968185424804687500;
         0.3581303270326594012651355569687439128756523132324218750]

  trueProbP = ones(Float64, n, n)
  idx = 0
  for j in 1:(n - 1), i in (j + 1):n
    idx += 1
    trueProbP[i, j] = trueProbP[j, i] = tmp[idx]
  end

  trueProbS = permutedims(
    reshape([0.6350275618390684995162587256345432251691818237304688;
             0.6350275618390672782709316379623487591743469238281250;
             0.6821394899702427627730116910242941230535507202148438;
             0.6769128361810061722536602246691472828388214111328125;
             0.3271348717192160138189649387641111388802528381347656;
             0.3271348717192145705290329260606085881590843200683594;
             0.2895518564454515608730389431002549827098846435546875;
             0.2864517226506904656879726189799839630722999572753906;
             0.0378375664417737456179935406908043660223484039306641;
             0.0378375664417758481028464245810027932748198509216309;
             0.0283086535842254523320793424545627203769981861114502;
             0.0366354411681910074882750905089778825640678405761719],
            (4, 3)))

  Kpax3.kpax3mcmc(x, partition, settings)

  (k, estimK) = Kpax3.readposteriork(settings.ofile)
  (id, estimP) = Kpax3.readposteriorP(settings.ofile)
  (site, aa, freq, estimS) = Kpax3.readposteriorC(settings.ofile)

  @test isapprox(estimK, trueProbK, rtol=0.02)
  @test isapprox(estimP, trueProbP, rtol=0.02)
  @test isapprox(estimS, trueProbS, rtol=0.02)

  nothing
end

test_mcmc_algorithm()
