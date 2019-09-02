# This file is part of Kpax3. License is MIT.

function initializepartition(settings::KSettings;
                             kset::UnitRange{Int}=1:0)
  if settings.verbose
    Printf.@printf("Computing pairwise distances... ")
  end

  tmp = zeros(UInt8, length(settings.miss))
  idx = 0
  for c in 1:length(settings.miss)
    if settings.miss[c] != UInt8('-')
      idx += 1
      tmp[idx] = settings.miss[c]
    end
  end

  miss = if idx > 0
           copyto!(zeros(UInt8, idx), 1, tmp, 1, idx)
         else
           zeros(UInt8, 1)
         end

  (data, id, ref) = readfasta(settings.ifile, settings.protein, miss,
                              settings.l, false, 0)

  n = size(data, 2)

  d = if settings.protein
        distaamtn84(data, ref)
      else
        distntmtn93(data, ref)
      end

  D = zeros(Float64, n, n)
  idx = 0
  for j in 1:(n - 1), i in (j + 1):n
    idx += 1
    D[i, j] = D[j, i] = d[idx]
  end

  if settings.verbose
    Printf.@printf("done\n")
  end

  # expected number of cluster approximately between cbrt(n) and sqrt(n)
  g = ceil(Int, n^(2 / 5))

  kset = if length(kset) == 0
           max(1, g - 20):min(n, g + 20)
         elseif kset[1] > 0
           if kset[end] > n
             if kset[1] == 1
               2:n
             else
               kset[1]:n
             end
           else
             if kset[1] == 1
               2:kset[end]
             else
               kset[1]:kset[end]
             end
           end
         else
           throw(KDomainError("First element of 'kset' is less than one."))
         end

  if settings.verbose
    Printf.@printf("Initializing partition...\n")
  end

  missval = if (length(settings.miss) == 1) && (settings.miss[1] == 0x00)
              0x00
            else
              UInt8('?')
            end

  (data1, id1, ref1) = readfasta(settings.ifile, settings.protein,
                                 settings.miss, settings.l, false, 0)
  (bindata, val, key) = categorical2binary(data1, UInt8(127), missval)

  priorR = EwensPitman(settings.α, settings.θ)
  priorC = AminoAcidPriorCol(bindata, settings.γ, settings.r)

  s = initializestate(bindata, D, kset, priorR, priorC, settings)

  if settings.verbose
    Printf.@printf("Initialization done.\n")
  end

  normalizepartition(s.R, n)
end

function initializepartition(data::Matrix{UInt8},
                             D::Matrix{Float64},
                             settings::KSettings;
                             kset::UnitRange{Int}=1:0)
  n = size(data, 2)

  # expected number of cluster approximately between cbrt(n) and sqrt(n)
  g = ceil(Int, n^(2 / 5))

  kset = if length(kset) == 0
           max(1, g - 20):min(n, g + 20)
         elseif kset[1] > 0
           if kset[end] > n
             if kset[1] == 1
               2:n
             else
               kset[1]:n
             end
           else
             if kset[1] == 1
               2:kset[end]
             else
               kset[1]:kset[end]
             end
           end
         else
           throw(KDomainError("First element of 'kset' is less than one."))
         end

  if settings.verbose
    Printf.@printf("Initializing partition...\n")
  end

  priorR = EwensPitman(settings.α, settings.θ)
  priorC = AminoAcidPriorCol(data, settings.γ, settings.r)

  s = initializestate(data, D, kset, priorR, priorC, settings)

  if settings.verbose
    Printf.@printf("Initialization done.\n")
  end

  normalizepartition(s.R, n)
end

"""
remove "gaps" and non-positive values from the partition
Example: [1, 1, 0, 1, -2, 4, 0] -> [3, 3, 2, 3, 1, 4, 2]
"""
function normalizepartition(partition::Vector{Int},
                            n::Int)
  if length(partition) != n
    throw(KInputError(string("Length of argument 'partition' is not equal to ",
                             "the sample size: ", length(partition),
                             " instead of ", n, ".")))
  end

  map(Int, indexin(partition, sort(unique(partition))))
end

function normalizepartition(ifile::String,
                            n::Int)
  d = DelimitedFiles.readdlm(ifile, ',', Int)

  if size(d, 2) != 1
    throw(KInputError(string("Too many columns found in file ", ifile, ".")))
  end

  if length(d) != n
    throw(KInputError(string("Partition length is not equal to the sample ",
                             "size: ", length(d), " instead of ", n, ".")))
  end

  map(Int, indexin(d[:, 1], sort(unique(d[:, 1]))))
end

function normalizepartition(ifile::String,
                            id::Vector{String})
  d = DelimitedFiles.readdlm(ifile, ',', String)

  if size(d, 1) != length(id)
    throw(KInputError(string("Partition length is not equal to the sample ",
                             "size: ", size(d, 1), " instead of ", length(id),
                             ".")))
  end

  if size(d, 2) == 1
    partition = [parse(Int, x) for x in d[:, 1]]
    map(Int, indexin(partition, sort(unique(partition))))
  elseif size(d, 2) == 2
    idx = map(Int, indexin(id, [x::String for x in d[:, 1]]))
    partition = [parse(Int, x) for x in d[:, 2]]

    for i in 1:length(idx)
      if idx[i] == 0
        throw(KInputError(string("Missing ids in file ", ifile, ".")))
      end
    end

    map(Int, indexin(partition, sort(unique(partition)))[idx])
  else
    throw(KInputError(string("Too many columns found in file ", ifile, ".")))
  end
end

function decodepartition!(R::Vector{Int})
  for a in 1:length(R)
    R[a] = 1 + div(R[a] - a, length(R))
  end

  nothing
end

function encodepartition!(R::Vector{Int},
                          S::Vector{Int})
  n = length(S)

  lidx = zeros(Int, n)

  g = 0
  for a in 1:n
    g = S[a]

    if lidx[g] == 0
      lidx[g] = a
    end

    # linear index of unit a in the n-by-n adjacency matrix
    R[a] = a + n * (lidx[g] - 1)
  end

  nothing
end

function modifypartition!(R::Vector{Int},
                          k::Int)
  n = length(R)
  q = k

  if (k > 0) && (k < n + 1)
    q = rand(max(1, k - 10):min(n, k + 10))

    if q < k
      modifymerge!(R, k, q)
    elseif q > k
      modifysplit!(R, k, q)
    else
      modifyscramble!(R, k)
    end
  end

  q
end

function modifymerge!(R::Vector{Int},
                      k::Int,
                      q::Int)
  n = length(R)

  cset = zeros(Int, k)
  empty = trues(n)
  l = 1
  for a in 1:n
    if empty[R[a]]
      empty[R[a]] = false
      cset[l] = R[a]
      l += 1
    end
  end

  c = zeros(Int, 2)

  while k != q
    StatsBase.sample!(cset, c, replace=false, ordered=false)

    for a in 1:n
      if R[a] == c[2]
        R[a] = c[1]
      end
    end

    l = 1
    while cset[l] != c[2]
      l += 1
    end

    deleteat!(cset, l)
    k -= 1
  end

  nothing
end

function modifysplit!(R::Vector{Int},
                      k::Int,
                      q::Int)
  n = length(R)

  t = zeros(Int, n)
  for a in 1:n
    t[R[a]] += 1
  end

  g = 0

  while k != q
    k += 1

    w = StatsBase.ProbabilityWeights(Float64[t[a] > 0 ? t[a] - 1 : 0
                                             for a in 1:n])
    g = StatsBase.sample(w)

    for a in 1:n
      if (R[a] == g) && ((t[k] == 0) || (rand() <= 0.25))
        R[a] = k
        t[g] -= 1
        t[k] += 1
      end
    end
  end

  nothing
end

function modifyscramble!(R::Vector{Int},
                         k::Int)
  n = length(R)

  t = zeros(Int, n)
  for a in 1:n
    t[R[a]] += 1
  end

  v = zeros(Int, n)
  moved = false

  l = 1
  g = 1
  h = 1
  while g < k
    if t[l] > 0
      t[l] = 0
      v[l] = 0

      for a in (l + 1):n
        v[a] = t[a] > 0 ? t[a] - 1 : 0
      end

      w = StatsBase.ProbabilityWeights(v)
      h = StatsBase.sample(w)

      keepgoing = true
      moved = false
      a = 1
      while keepgoing
        if R[a] == h
          if moved
            if rand() <= 0.05
              R[a] = g
              t[h] -= 1

              if t[h] == 1
                keepgoing = false
              end
            end
          else
            moved = true
            R[a] = g
            t[h] -= 1

            if t[h] == 1
              keepgoing = false
            end
          end
        end

        a += 1
        if a > n
          keepgoing = false
        end
      end

      g += 1
    end

    l += 1
  end

  nothing
end
