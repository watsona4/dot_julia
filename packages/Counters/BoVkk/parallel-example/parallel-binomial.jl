using Distributions
using Counters

"""
`binom_rv(n,p)` generates a single random value according to
the binomial distribution `B(n,p)`.
"""
binom_rv(n::Int,p::Real=0.5) = rand(Binomial(n,p))

"""
`binomial_counts(n,p,reps)` generates `reps` binomial random values `B(n,p)`
returning a `Counter` that reports how many times each value was observed.
"""
function binomial_counts(n::Int, p::Real, reps::Int)
  c = Counter{Int}()
  for k=1:reps
    x = binom_rv(n,p)
    c[x] += 1
  end
  return c
end

"""
`parallel_binomial_counts(n,p,reps,rounds)` generates `reps*rounds`
binomial random values `B(n,p)` returning a `Counter` that reports how
many times each value was observed. In this regard, this is the same
as `binomial_counts`. However, this is done by multiple processors by
making `rounds` calls to `binomial_counts(n,p,reps)` and combining
the results.
"""
function parallel_binomial_counts(n::Int, p::Real, reps::Int, rounds::Int)
  counts = @parallel (+) for k=1:rounds
    binomial_counts(n,p,reps)
  end
  return counts
end
