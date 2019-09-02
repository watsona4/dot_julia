# This file is part of Kpax3. License is MIT.

function test_mcmc_clusterweight()
  n = 10
  k = 2

  priorR = Kpax3.EwensPitman(0.5, -0.1)
  @test isapprox(Kpax3.clusterweight(n, priorR), log(n - 0.5), atol=ε)

  priorR = Kpax3.EwensPitman(0.5, 0.0)
  @test isapprox(Kpax3.clusterweight(n, priorR), log(n - 0.5), atol=ε)

  priorR = Kpax3.EwensPitman(0, 2.0)
  @test isapprox(Kpax3.clusterweight(n, priorR), log(n), atol=ε)

  priorR = Kpax3.EwensPitman(-2, 5)
  @test isapprox(Kpax3.clusterweight(n, priorR), log(n + 2.0), atol=ε)

  priorR = Kpax3.EwensPitman(0.5, -0.1)
  @test isapprox(Kpax3.clusterweight(n, k, priorR), log(0.5 * k - 0.1), atol=ε)

  priorR = Kpax3.EwensPitman(0.5, 0.0)
  @test isapprox(Kpax3.clusterweight(n, k, priorR), log(0.5 * k), atol=ε)

  priorR = Kpax3.EwensPitman(0, 2.0)
  @test isapprox(Kpax3.clusterweight(n, k, priorR), log(2), atol=ε)

  priorR = Kpax3.EwensPitman(-2, 5)
  @test isapprox(Kpax3.clusterweight(n, k, priorR), log(-2.0 * (k - 5)), atol=ε)

  nothing
end

test_mcmc_clusterweight()
