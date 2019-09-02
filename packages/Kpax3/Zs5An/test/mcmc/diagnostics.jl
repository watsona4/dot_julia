# This file is part of Kpax3. License is MIT.

# these tests must be run after "mcmc/posterior.jl"
function test_traceR()
  fileroot = "../build/mcmc_6"
  maxlag = 20

  (entropy, avgd) = Kpax3.traceR(fileroot, maxlag=maxlag)

  fpR = open(string(fileroot, "_row_partition.bin"), "r")

  tmp = zeros(Int, 1)

  read!(fpR, tmp)
  n = tmp[1]

  read!(fpR, tmp)
  read!(fpR, tmp)
  N = tmp[1]

  k = zeros(Int, N)
  R = zeros(Int, n, N)
  v = zeros(Int, n, N)

  e = 0.0

  k0 = zeros(Int, 1)
  R0 = zeros(Int, n)

  T = 1
  while !eof(fpR)
    read!(fpR, k0)
    read!(fpR, R0)

    k[T] = k0[1]
    copyto!(R, 1 + n * (T - 1), Kpax3.normalizepartition(R0, n), 1, n)

    for i in 1:n
      v[R[i, T], T] += 1
    end

    e = 0.0
    for g in 1:k[T]
      e -= v[g, T] * (log(v[g, T]) - log(n)) / n
    end

    @test isapprox(entropy[T], e, atol=ε)

    T += 1
  end

  close(fpR)

  # test lag 1
  l = 1
  z = zeros(Float64, N - l)
  for t in 1:(N - l)
    z[t] = Kpax3.jaccard(R[:, t], k[t], R[:, t+l], k[t+l], n)
  end
  @test isapprox(avgd[l], Statistics.mean(z), atol=ε)

  # test lag 5
  l = 5
  z = zeros(Float64, N - l)
  for t in 1:(N - l)
    z[t] = Kpax3.jaccard(R[:, t], k[t], R[:, t+l], k[t+l], n)
  end
  @test isapprox(avgd[l], Statistics.mean(z), atol=ε)

  # test lag 13
  l = 13
  z = zeros(Float64, N - l)
  for t in 1:(N - l)
    z[t] = Kpax3.jaccard(R[:, t], k[t], R[:, t+l], k[t+l], n)
  end
  @test isapprox(avgd[l], Statistics.mean(z), atol=ε)

  nothing
end

test_traceR()

function test_traceC()
  fileroot = "../build/mcmc_6"
  maxlag = 20

  (entropy, avgd) = Kpax3.traceC(fileroot, maxlag=maxlag)

  fpC = open(string(fileroot, "_col_partition.bin"), "r")

  tmp = zeros(Int, 1)

  read!(fpC, tmp)
  n = tmp[1]

  read!(fpC, tmp)
  m = tmp[1]

  read!(fpC, tmp)
  N = tmp[1]

  C = zeros(UInt8, m, N)
  e = 0.0

  C0 = zeros(UInt8, m)
  v0 = zeros(Float64, 3)

  T = 1
  while !eof(fpC)
    readbytes!(fpC, C0, m)
    copyto!(C, 1 + m * (T - 1), C0, 1, m)

    fill!(v0, 0.0)
    for b in 1:m
      v0[C[b, T]] += 1
    end
    v0 /= m

    e = 0.0
    if v0[1] > 0.0
      e -= v0[1] * log(v0[1])
    end

    if v0[2] > 0.0
      e -= v0[2] * log(v0[2])
    end

    if v0[3] > 0.0
      e -= v0[3] * log(v0[3])
    end

    @test isapprox(entropy[T], e, atol=ε)

    T += 1
  end

  close(fpC)

  # test lag 1
  l = 1
  z = zeros(Float64, N - l)
  for t in 1:(N - l)
    z[t] = Distances.hamming(C[:, t], C[:, t + l]) / m
  end
  @test isapprox(avgd[l], Statistics.mean(z), atol=ε)

  # test lag 5
  l = 5
  z = zeros(Float64, N - l)
  for t in 1:(N - l)
    z[t] = Distances.hamming(C[:, t], C[:, t + l]) / m
  end

  @test isapprox(avgd[l], Statistics.mean(z), atol=ε)

  # test lag 13
  l = 13
  z = zeros(Float64, N - l)
  for t in 1:(N - l)
    z[t] = Distances.hamming(C[:, t], C[:, t + l]) / m
  end

  @test isapprox(avgd[l], Statistics.mean(z), atol=ε)

  nothing
end

test_traceC()

function test_imsevar()
  fileroot = "../build/mcmc_6"
  maxlag = 20

  N = 100
  ac = [ 1.3916266386374644969947667050291784107685089111328125;
         0.58693069919258922251259491531527601182460784912109375;
         0.10875873500110790070838362453287118114531040191650390625;
         0.1399794990760882262836872769184992648661136627197265625;
        -0.06737442536689319805276454644626937806606292724609375;
        -0.282376530912865408851075699203647673130035400390625;
        -0.2376229639169518126351476894342340528964996337890625;
        -0.12117094585437278297934682314007659442722797393798828125;
        -0.3315812679619776215389492790563963353633880615234375;
        -0.2608754424296446661202253380906768143177032470703125;
         0.07139428050428296701479524699607281945645809173583984375;
        -0.056644446311564296270280038925193366594612598419189453125;
        -0.028541953982895558461496676727620069868862628936767578125;
         0.1310526295294208998232221574653522111475467681884765625;
         0.037620699765729091745836143445558263920247554779052734375;
        -0.2301652651239802782612287046504206955432891845703125;
        -0.063254641673751998975916421841247938573360443115234375;
         0.097048399599290402495199714394402690231800079345703125;
        -0.0192219724107511556743244085510013974271714687347412109375;
        -0.097383940885847675161812730948440730571746826171875;
        -0.0578078906440780693198888684491976164281368255615234375]

  z = 0.0306296450517703523763746176200584159232676029205322265625

  @test isapprox(Kpax3.imsevar(ac, N), z, atol=ε)

  nothing
end

test_imsevar()

function test_ess()
  @test Kpax3.ess(1.0, 1.0, 10) == 10
  @test Kpax3.ess(2.0, 2.0, 100) == 100

  @test Kpax3.ess(2.0, 4.0, 10) == 5
  @test Kpax3.ess(2.0, 4.0, 100) == 50

  @test Kpax3.ess(4.0, 2.0, 10) == 20
  @test Kpax3.ess(4.0, 2.0, 100) == 200

  @test Kpax3.ess(4.0, 12.0, 10) == 3
  @test Kpax3.ess(4.0, 12.0, 100) == 33

  @test Kpax3.ess(4.0, 16.0, 10) == 2
  @test Kpax3.ess(4.0, 16.0, 100) == 25

  nothing
end

test_ess()
