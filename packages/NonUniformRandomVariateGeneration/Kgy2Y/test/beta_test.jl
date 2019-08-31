import StatsFuns.betacdf

seed!(12345)

function testBeta(α, β, low, high, h, N)
  function cdf(x::Float64)
    return betacdf(α, β, x)
  end
  function sampler()
    return sampleBeta(α, β)
  end
  return testGOFContinuous(cdf, sampler, low, high, h, N)
end

@test testBeta(3.0, 2.0, 0.05, 0.95, 0.01, 2^21) > 0.01
@test testBeta(0.1, 0.2, 0.05, 0.95, 0.01, 2^21) > 0.01
@test testBeta(0.8, 12.3, 0.01, 0.55, 0.01, 2^21) > 0.01
@test testBeta(10.0, 25.0, 0.1, 0.6, 0.01, 2^21) > 0.01
