seed!(12345)

function testCategorical1(n::Int64, p::Vector{Float64})
  vs::Vector{Int64} = sampleCategorical(n, p)
  counts = Vector{Int64}(undef, length(p))
  fill!(counts, 0)
  for i in 1:n
    v::Int64 = vs[i]
    @inbounds counts[vs[i]] += 1
  end
  return testGOFMultinomial(p, counts)
end

function testCategorical2(n::Int64, p::Vector{Float64})
  counts = Vector{Int64}(undef, length(p))
  fill!(counts, 0)
  for i in 1:n
    v::Int64 = sampleCategorical(p)
    @inbounds counts[v] += 1
  end
  return testGOFMultinomial(p, counts)
end

@test testCategorical1(100, [0.5; 0.1; 0.25; 0.15]) > 0.01
@test testCategorical1(10000, [0.5; 0.1; 0.25; 0.15]) > 0.01

@test testCategorical2(100, [0.5; 0.1; 0.25; 0.15]) > 0.01
@test testCategorical2(10000, [0.5; 0.1; 0.25; 0.15]) > 0.01
