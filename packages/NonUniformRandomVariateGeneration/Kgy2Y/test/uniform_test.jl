seed!(12345)

function testSortedUniforms(low, high, h, N)
  function cdf(x::Float64)
    return x
  end
  samples = sampleSortedUniforms(N)
  ## check that they are sorted first
  for j in 2:N
    if samples[j] < samples[j-1]
      return 0.0
    end
  end
  i::Int64 = 0
  function sampler()
    i = i + 1
    return samples[i]
  end
  return testGOFContinuous(cdf, sampler, low, high, h, N)
end

@test testSortedUniforms(0.01, 0.99, 0.01, 2^21) > 0.01
@test testSortedUniforms(0.02, 0.98, 0.02, 2^10) > 0.01
