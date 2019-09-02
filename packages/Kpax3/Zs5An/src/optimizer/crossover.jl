# This file is part of Kpax3. License is MIT.

function crossover!(R1::Vector{Int},
                    R2::Vector{Int},
                    support::GASupport)
  fill!(support.oi.v, 0)
  fill!(support.oj.v, 0)

  encodepartition!(support.oi.R, R1)
  encodepartition!(support.oj.R, R2)

  # sample element on the diagonal (excluding 1)
  g = StatsBase.sample(2:support.n)

  # convert to linear index
  cutpoint = (g - 1) + support.n * (g - 1)

  # unit 1 is always found in cluster 1
  support.oi.v[1] = 1
  support.oj.v[1] = 1

  # vector of weights to compute probabilities (if needed)
  w = zeros(Int, support.n)

  for a in 2:support.n
    if support.oi.R[a] > cutpoint
      if support.oj.R[a] > cutpoint
        # no problem with this move, swap elements
        (support.oi.R[a], support.oj.R[a]) = (support.oj.R[a], support.oi.R[a])

        support.oi.v[1 + div(support.oi.R[a] - a, support.n)] += 1
        support.oj.v[1 + div(support.oj.R[a] - a, support.n)] += 1
      else
        # oj is receiving a "good" cluster but oi got broken
        support.oj.R[a] = support.oi.R[a]

        # we need to decide where to put a: an existing cluster or a new one?
        copyto!(w, 1, support.oi.v, 1, a - 1)
        w[a] = 1
        g = StatsBase.sample(StatsBase.ProbabilityWeights(w[1:a], a))

        support.oi.R[a] = a + support.n * (g - 1)

        support.oi.v[g] += 1
        support.oj.v[1 + div(support.oj.R[a] - a, support.n)] += 1
      end
    elseif support.oj.R[a] > cutpoint
      # oi is receiving a "good" cluster but oj got broken
      support.oi.R[a] = support.oj.R[a]

      # we need to decide where to put a: an existing cluster or a new one?
      copyto!(w, 1, support.oj.v, 1, a - 1)
      w[a] = 1
      g = StatsBase.sample(StatsBase.ProbabilityWeights(w[1:a], a))

      support.oj.R[a] = a + support.n * (g - 1)

      support.oi.v[1 + div(support.oi.R[a] - a, support.n)] += 1
      support.oj.v[g] += 1
    else
      support.oi.v[1 + div(support.oi.R[a] - a, support.n)] += 1
      support.oj.v[1 + div(support.oj.R[a] - a, support.n)] += 1
    end
  end

  decodepartition!(support.oi.R)
  decodepartition!(support.oj.R)

  nothing
end
