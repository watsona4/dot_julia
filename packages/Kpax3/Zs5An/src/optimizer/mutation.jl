# This file is part of Kpax3. License is MIT.

function mutation!(o::KOffspring,
                   mrate::Float64)
  n = length(o.R)

  w = zeros(Int, n)
  found = false
  t = 0
  i = 0

  for a in 1:n
    if rand() <= mrate
      # remove a from its cluster
      o.v[o.R[a]] -= 1
      t = o.v[o.R[a]]

      copyto!(w, o.v)

      # do not put i back into its cluster
      if t > 0
        # candidate empty cluster to be filled
        found = false
        i = 0
        while !found && i < n
          i += 1
          if w[i] == 0
            w[i] = 1
            found = true
          end
        end

        w[o.R[a]] = 0
      end

      o.R[a] = StatsBase.sample(StatsBase.ProbabilityWeights(w, n - t))
      o.v[o.R[a]] += 1
    end
  end

  nothing
end
