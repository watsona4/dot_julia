import StatsFuns.gammacdf

seed!(12345)

function testGamma(α, β, low, high, h, N)
  function cdf(x::Float64)
    return gammacdf(α, 1/β, x)
  end
  function sampler()
    return sampleGamma(α, β)
  end
  return testGOFContinuous(cdf, sampler, low, high, h, N)
end

@test testGamma(3.0, 2.0, 0.01, 6.0, 0.01, 2^21) > 0.01
@test testGamma(0.1, 1.0, 0.00, 4.0, 0.01, 2^21) > 0.01
@test testGamma(0.8, 1.0, 0.00, 7.0, 0.01, 2^21) > 0.01
@test testGamma(10.0, 1.0, 3.0, 23.0, 0.01, 2^21) > 0.01
