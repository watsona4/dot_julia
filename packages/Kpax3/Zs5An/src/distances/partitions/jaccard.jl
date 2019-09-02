function jaccard_index_basic(a::Vector{Int},
                             b::Vector{Int},
                             v::Int)
  agree = 0.0
  disagree = 0.0

  for j in 1:(v - 1), i in (j + 1):v
    if (a[i] == a[j]) && (b[i] == b[j])
      agree += 1
    elseif ((a[i] == a[j]) && (b[i] != b[j])) ||
           ((a[i] != a[j]) && (b[i] == b[j]))
      disagree += 1
    end
  end

  (agree > 0 || disagree > 0) ? agree / (agree + disagree) : 1.0
end

function jaccard_index_table(a::Vector{Int},
                             ka::Int,
                             b::Vector{Int},
                             kb::Int,
                             v::Int)
  agree = 0.0
  disagree = 0.0

  count = zeros(Float64, ka, kb)
  for i in 1:v
    count[a[i], b[i]] += 1.0
  end

  za = zeros(Float64, ka)
  zb = 0.0
  zab = 0.0

  for j in 1:kb
    zb = 0.0

    for i in 1:ka
      za[i] += count[i, j]
      zb += count[i, j]
      zab += count[i, j]^2

      agree += count[i, j] * (count[i, j] - 1) / 2
    end

    disagree += zb^2
  end

  for i in 1:ka
    disagree += za[i]^2
  end

  disagree /= 2
  disagree -= zab

  (agree > 0 || disagree > 0) ? agree / (agree + disagree) : 1.0
end

function jaccard(a::Vector{Int},
                 ka::Int,
                 b::Vector{Int},
                 kb::Int,
                 v::Int)
  # total number of for iterations for jaccard_index_table is v + ka + ka * kb
  # v iterations to compute counts
  # ka * kb iterations to compute various quantities
  # ka final iterations to compute row sums

  # total number of for iterations for jaccard_index_basic is v * (v - 1) / 2
  # which is equivalent to the total number of distinct pairs
  index = if (v + ka * (1 + kb)) < (v * (v - 1) / 2)
    jaccard_index_table(a, ka, b, kb, v)
  else
    jaccard_index_basic(a, b, v)
  end

  1.0 - index
end

function jaccardlower(n::Vector{T},
                      k::Int,
                      v::Real) where T <: Real
  agree = 0.0
  disagree = 0.0

  zab = 0.0
  for g in 1:k
    zab += n[g]^2

    agree += n[g] * (n[g] - 1) / 2
    disagree += n[g]^2
  end

  disagree = (disagree + v^2) / 2 - zab

  (agree > 0 || disagree > 0) ? 1.0 - agree / (agree + disagree) : 0.0
end
