seed!(12345)

function testMultinomial(n::Int64, p::Vector{Float64})
  counts::Vector{Int64} = sampleMultinomial(n, p)
  return testGOFMultinomial(p, counts)
end

@test testMultinomial(100, [0.5; 0.1; 0.25; 0.15]) > 0.01
@test testMultinomial(10000, [0.5; 0.1; 0.25; 0.15]) > 0.01
