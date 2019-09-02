# This file is part of Kpax3. License is MIT.

#=
References:

Tajima F. and Nei M. (1984). Estimation of evolutionary distance between
nucleotide sequences. Mol Biol Evol 1 (3):269-285.
http://mbe.oxfordjournals.org/content/1/3/269

Tamura K. and Kumar S. (2002). Evolutionary Distance Estimation Under
Heterogeneous Substitution Pattern Among Lineages. Mol Biol Evol 19 (10):
1727-1736. http://mbe.oxfordjournals.org/content/19/10/1727
=#

#=
Description:

Compute Tajima Nei (1984) pairwise distances of dna sequences.

Arguments:

  data::Matrix{UInt8}
    m-by-n data matrix, where m is the common sequence length and n is the
    sample size
  ref::Vector{UInt8}
    reference sequence, i.e. a vector of length m storing the values of
    homogeneous sites

Details:

Only the four basic nucleotides are considered in the computations. It is
expected that Uracil has a value of 4 (equal to Thymidine).

If a pairwise distance is equal to -1.0, it means that is wasn't possible to
compute it. This usually happens when the hypotheses of the underlying
evolutionary model are not satisfied.

Value:

  d::Vector{Float64}
    evolutionary distances. Vector length is equal to n * (n - 1) / 2. It
    contains the values of the lower triangular matrix of the full distance
    matrix, ordered by column.
    To access the distance between units i and j (i < j), use
    d[n * (i - 1) - div(i * (i - 1), 2) + j - i]
=#
function distnttn84(data::Matrix{UInt8},
                    ref::Vector{UInt8})
  (m, n) = size(data)

  d = zeros(Float64, div(n * (n - 1), 2))

  gt = zeros(Float64, 4)
  gb = zeros(Float64, 4)
  gp = zeros(Float64, 6)

  a = UInt8('a')
  c = UInt8('c')
  g = UInt8('g')
  t = UInt8('t')

  for j in 1:m
    if ref[j] == a
      gt[1] += 1
    elseif ref[j] == c
      gt[2] += 1
    elseif ref[j] == g
      gt[3] += 1
    elseif ref[j] == t
      gt[4] += 1
    end
  end

  for i in 1:n, j in 1:m
    if data[j, i] == a
      gb[1] += 1
    elseif data[j, i] == c
      gb[2] += 1
    elseif data[j, i] == g
      gb[3] += 1
    elseif data[j, i] == t
      gb[4] += 1
    end
  end

  gb[1] += n * gt[1]
  gb[2] += n * gt[2]
  gb[3] += n * gt[3]
  gb[4] += n * gt[4]

  tot = gb[1] + gb[2] + gb[3] + gb[4]

  gb[1] /= tot
  gb[2] /= tot
  gb[3] /= tot
  gb[4] /= tot

  h = gt[1] + gt[2] + gt[3] + gt[4]

  gp[1] = 2 * gb[1] * gb[2]
  gp[2] = 2 * gb[1] * gb[3]
  gp[3] = 2 * gb[1] * gb[4]
  gp[4] = 2 * gb[2] * gb[3]
  gp[5] = 2 * gb[2] * gb[4]
  gp[6] = 2 * gb[3] * gb[4]

  v = 1 - (gb[1]^2 + gb[2]^2 + gb[3]^2 + gb[4]^2)

  idx = 1
  for j in 1:(n - 1), i in (j + 1):n
    d[idx] = nttn84(i, j, data, gp, h, v)
    idx += 1
  end

  d
end

#=
Description:

Compute Tajima Nei (1984) pairwise distances of dna sequences, with the Tamura
and Kumar (2002) correction for heterogeneous patterns.

Arguments:

  data::Matrix{UInt8}
    m-by-n data matrix, where m is the common sequence length and n is the
    sample size
  ref::Vector{UInt8}
    reference sequence, i.e. a vector of length m storing the values of
    homogeneous sites

Details:

Only the four basic nucleotides are considered in the computations. It is
expected that Uracil has a value of 4 (equal to Thymidine).

If a pairwise distance is equal to -1.0, it means that is wasn't possible to
compute it. This usually happens when the hypotheses of the underlying
evolutionary model are not satisfied.

Value:

  d::Vector{Float64}
    evolutionary distances. Vector length is equal to n * (n - 1) / 2. It
    contains the values of the lower triangular matrix of the full distance
    matrix, ordered by column.
    To access the distance between units i and j (i < j), use
    d[n * (i - 1) - div(i * (i - 1), 2) + j - i]
=#
function distntmtn84(data::Matrix{UInt8},
                     ref::Vector{UInt8})
  (m, n) = size(data)

  d = zeros(Float64, div(n * (n - 1), 2))

  gt = zeros(Float64, 4)
  gb = zeros(Float64, 4)

  a = UInt8('a')
  c = UInt8('c')
  g = UInt8('g')
  t = UInt8('t')

  for j in 1:m
    if ref[j] == a
      gt[1] += 1
    elseif ref[j] == c
      gt[2] += 1
    elseif ref[j] == g
      gt[3] += 1
    elseif ref[j] == t
      gt[4] += 1
    end
  end

  for i in 1:n, j in 1:m
    if data[j, i] == a
      gb[1] += 1
    elseif data[j, i] == c
      gb[2] += 1
    elseif data[j, i] == g
      gb[3] += 1
    elseif data[j, i] == t
      gb[4] += 1
    end
  end

  gb[1] += n * gt[1]
  gb[2] += n * gt[2]
  gb[3] += n * gt[3]
  gb[4] += n * gt[4]

  tot = gb[1] + gb[2] + gb[3] + gb[4]

  gb[1] /= tot
  gb[2] /= tot
  gb[3] /= tot
  gb[4] /= tot

  h = gt[1] + gt[2] + gt[3] + gt[4]

  v = 1 - (gb[1]^2 + gb[2]^2 + gb[3]^2 + gb[4]^2)

  idx = 1
  for j in 1:(n - 1), i in (j + 1):n
    d[idx] = ntmtn84(i, j, data, gt, h, v)
    idx += 1
  end

  d
end

#=
Description:

Compute the Tajima Nei (1984) distance between two dna sequences.

Arguments:

  i::Int
    index of first sequence
  j::Int
    index of second sequence
  data::Matrix{UInt8}
    m-by-n data matrix, where m is the common sequence length and n is the
    sample size
  h::Float64
    total number of homogeneous sites that are not missing
  gp::Vector{Float64}
    proportions (probabilities) of nucleotide pairs computed on the whole
    dataset
  v::Float64
    v = 1 - sum(pi^2), where pi is the proportion of nucleotide i observed in
    the whole dataset

Value:

  d::Float64
    evolutionary distance between the two dna sequences
=#
function nttn84(i::Int,
                j::Int,
                data::Matrix{UInt8},
                gp::Vector{Float64},
                h::Float64,
                v::Float64)
  d = -1.0

  # proportion of different elements
  p = 0.0

  # proportion of nucleotide pairs
  pn = zeros(Float64, 6)

  w = 0.0
  x = 0.0
  z = 0.0

  x1 = 0x00
  x2 = 0x00

  a = UInt8('a')
  c = UInt8('c')
  g = UInt8('g')
  t = UInt8('t')

  for b in 1:size(data, 1)
    x1 = data[b, i]
    x2 = data[b, j]

    if (x1 == a || x1 == c || x1 == g || x1 == t) &&
       (x2 == a || x2 == c || x2 == g || x2 == t)
      if x1 != x2
        p += 1

        if     ((x1 == a) && (x2 == c)) || ((x1 == c) && (x2 == a))
          pn[1] += 1
        elseif ((x1 == a) && (x2 == g)) || ((x1 == g) && (x2 == a))
          pn[2] += 1
        elseif ((x1 == a) && (x2 == t)) || ((x1 == t) && (x2 == a))
          pn[3] += 1
        elseif ((x1 == c) && (x2 == g)) || ((x1 == g) && (x2 == c))
          pn[4] += 1
        elseif ((x1 == c) && (x2 == t)) || ((x1 == t) && (x2 == c))
          pn[5] += 1
        elseif ((x1 == g) && (x2 == t)) || ((x1 == t) && (x2 == g))
          pn[6] += 1
        end
      end

      h += 1
    end
  end

  if p > 0
    p /= h
    pn /= h

    z = pn[1]^2 / gp[1] + pn[2]^2 / gp[2] + pn[3]^2 / gp[3] +
        pn[4]^2 / gp[4] + pn[5]^2 / gp[5] + pn[6]^2 / gp[6]

    x = (v + p^2 / z) / 2

    w = 1 - p / x

    if w > 0
      d = - x * log(w)
    end
  else
    # sequences are identical (or couldn't be compared because of missing
    # values. But in this case, by default, we consider them identical)
    d = 0.0
  end

  d
end

#=
Description:

Compute the Tajima Nei (1984) distance between two dna sequences, with the
Tamura and Kumar (2002) correction for heterogeneous patterns.

Arguments:

  i::Int
    index of first sequence
  j::Int
    index of second sequence
  data::Matrix{UInt8}
    m-by-n data matrix, where m is the common sequence length and n is the
    sample size
  gt::Vector{Float64}
    common absolute frequency for the 4 nucleotides, i.e. the count of each
    nucleotide at homogeneous sites
  h::Float64
    total number of homogeneous sites that are not missing
  v::Float64
    v = 1 - sum(pi^2), where pi is the proportion of nucleotide i observed in
    the whole dataset

Value:

  d::Float64
    evolutionary distance between the two dna sequences
=#
function ntmtn84(i::Int,
                 j::Int,
                 data::Matrix{UInt8},
                 gt::Vector{Float64},
                 h::Float64,
                 v::Float64)
  d = -1.0

  # effective length, i.e. total number of sites at which both sequences have
  # non-missing values
  n = fill(h, 3)

  # proportion of different elements
  p = 0.0

  # proportion of observed nucleotides
  g1 = copy(gt)
  g2 = copy(gt)

  f = 0.0
  w = 0.0

  x1 = 0x00
  x2 = 0x00

  a = UInt8('a')
  c = UInt8('c')
  g = UInt8('g')
  t = UInt8('t')

  for b in 1:size(data, 1)
    x1 = data[b, i]
    x2 = data[b, j]

    if (x1 == a || x1 == c || x1 == g || x1 == t)
      g1[x1] += 1
      n[1] += 1
    end

    if (x2 == a || x2 == c || x2 == g || x2 == t)
      g2[x2] += 1
      n[2] += 1
    end

    if (x1 == a || x1 == c || x1 == g || x1 == t) &&
       (x2 == a || x2 == c || x2 == g || x2 == t)
      if x1 != x2
        p += 1
      end

      n[3] += 1
    end
  end

  if p > 0
    g1 /= n[1]
    g2 /= n[2]

    p /= n[3]

    f = 1 - (g1[1] * g2[1] + g1[2] * g2[2] + g1[3] * g2[3] + g1[4] * g2[4])
    w = 1 - p / f

    if w > 0
      d = - v * log(w)
    end
  else
    # sequences are identical (or couldn't be compared because of missing
    # values. But in this case, by default, we consider them identical)
    d = 0.0
  end

  d
end
