import StatsFuns.poispdf

seed!(12345)

function testPoisson(μ, low, high, N)
  function pmf(x::Int64)
    return poispdf(μ, x)
  end
  function sampler()
    return samplePoisson(μ)
  end
  return testGOFDiscrete(pmf, sampler, low, high, N)
end

@test testPoisson(3.0, 0, 12, 2^21) > 0.01
@test testPoisson(15.0, 5, 30, 2^21) > 0.01
@test testPoisson(50.0, 25, 80, 2^21) > 0.01
