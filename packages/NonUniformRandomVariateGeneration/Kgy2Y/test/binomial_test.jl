import StatsFuns.binompdf

seed!(12345)

function testBinomial(n, p, low, high, N)
  function pmf(x::Int64)
    return binompdf(n, p, x)
  end
  function sampler()
    return sampleBinomial(n, p)
  end
  return testGOFDiscrete(pmf, sampler, low, high, N)
end

@test testBinomial(100, 0.5, 30, 60, 2^21) > 0.01
@test testBinomial(1000, 0.0001, 0, 3, 2^22) > 0.01
@test testBinomial(5, .25, 0, 4, 2^21) > 0.01
@test testBinomial(5, .001, 0, 1, 2^21) > 0.01
@test testBinomial(1000, 0.75, 700, 800, 2^22) > 0.01
@test testBinomial(10, 0.75, 2, 10, 2^22) > 0.01
