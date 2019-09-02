# This file is part of Kpax3. License is MIT.

function reorderunits(R::Vector{Int},
                      P::Matrix{Float64},
                      clusterorder::Vector{Int})
  n = length(R)
  k = maximum(R)

  M = zeros(Float64, n)
  v = zeros(Float64, n)
  for j in 1:(n - 1), i in (j + 1):n
    if R[i] == R[j]
      M[i] += P[i, j]
      v[i] += 1

      M[j] += P[i, j]
      v[j] += 1
    end
  end

  M ./= v

  neworder = zeros(Int, n)
  midpoint = zeros(Float64, k)
  seppoint = zeros(Float64, k + 1)

  h = 1
  u = 1
  for g in 1:k
    idx = findall(R .== clusterorder[g])
    u = length(idx)
    ord = sortperm(M[idx], rev=true)

    copyto!(neworder, h, idx[ord], 1, u)
    midpoint[g] = (2 * h + u - 1) / 2
    seppoint[g] = h - 0.5

    h += u
  end

  seppoint[k + 1] = n + 0.5

  (neworder, midpoint, seppoint)
end

function expandsquarediag(j::Int,
                          n::Int,
                          val::String,
                          z::Vector{String})
  # probability matrix is symmetric, so we only need to scan either the columns
  # or the rows. We scan the column because elements are sequential in
  # variable z
  h = j
  expand = true

  while expand && h < n
    idx = LinearIndices((n, n))[j, h + 1]

    i = j
    while expand && i <= h + 1
      if z[idx] != val
        expand = false
      end

      idx += 1
      i += 1
    end

    if expand
      h += 1
    end
  end

  h
end

function expandsquare(i::Int,
                      j::Int,
                      ni::Int,
                      nj::Int,
                      val::String,
                      z::Vector{String},
                      processed::BitArray{2})
  imax = i
  jmax = j
  expand = true

  while expand && imax < ni && jmax < nj
    # check next column from imin to imax + 1
    imin = i
    idx = LinearIndices((ni, nj))[imin, jmax + 1]

    while expand && imin <= imax + 1
      if processed[idx] || z[idx] != val
        expand = false
      end

      idx += 1
      imin += 1
    end

    # check next row from j to jmax + 1 only if column was ok
    if expand
      jmin = j
      while expand && jmin <= jmax + 1
        idx = LinearIndices((ni, nj))[imax + 1, jmin]

        if processed[idx] || z[idx] != val
          expand = false
        end

        jmin += 1
      end
    end

    if expand
      imax += 1
      jmax += 1
    end
  end

  (imax, jmax)
end

function expandrecthoriz(i::Int,
                         j::Int,
                         imax::Int,
                         jmax::Int,
                         ni::Int,
                         nj::Int,
                         val::String,
                         z::Vector{String},
                         processed::BitArray{2})
  expand = true

  while expand && jmax < nj
    idx = LinearIndices((ni, nj))[i, jmax + 1]

    imin = i
    while expand && imin <= imax
      if processed[idx] || z[idx] != val
        expand = false
      end

      idx += 1
      imin += 1
    end

    if expand
      jmax += 1
    end
  end

  jmax
end

function expandrectverti(i::Int,
                         j::Int,
                         imax::Int,
                         jmax::Int,
                         ni::Int,
                         nj::Int,
                         val::String,
                         z::Vector{String},
                         processed::BitArray{2})
  expand = true

  while expand && imax < ni
    jmin = j
    while expand && jmin <= jmax
      idx = LinearIndices((ni, nj))[imax + 1, jmin]

      if processed[idx] || z[idx] != val
        expand = false
      end

      jmin += 1
    end

    if expand
      imax += 1
    end
  end

  imax
end

function expandrect(i::Int,
                    j::Int,
                    ni::Int,
                    nj::Int,
                    val::String,
                    z::Vector{String},
                    processed::BitArray{2})
  (imax, jmax) = expandsquare(i, j, ni, nj, val, z, processed)

  h = expandrecthoriz(i, j, imax, jmax, ni, nj, val, z, processed)
  v = expandrectverti(i, j, imax, jmax, ni, nj, val, z, processed)

  if v - imax > h - jmax
    h = jmax
  elseif h - jmax > v -imax
    v = imax
  end

  (v, h)
end
