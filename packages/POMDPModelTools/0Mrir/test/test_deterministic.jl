d = Deterministic(1)

@test rand(d) == 1
@test rand(MersenneTwister(4), d) == 1
@test collect(support(d)) == [1]
@test sampletype(d) == typeof(1)
@test sampletype(typeof(d)) == typeof(1)
@test pdf(d, 0) == 0.0
@test pdf(d, 1) == 1.0
@test mode(d) == 1
@test mean(d) == 1
@test typeof(mean(d)) == typeof(mean([1]))

d2 = Deterministic(:symbol)
@test rand(d2) == :symbol
@test rand(MersenneTwister(4), d2) == :symbol
@test collect(support(d2)) == [:symbol]
@test sampletype(d2) == typeof(:symbol)
@test sampletype(typeof(d2)) == typeof(:symbol)
@test pdf(d2, :another) == 0.0
@test pdf(d2, :symbol) == 1.0
@test mode(d2) == :symbol
@test mean(d2) == :symbol
@test typeof(mean(d2)) == Symbol
