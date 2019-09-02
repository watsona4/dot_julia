# This file is part of Kpax3. License is MIT.

"""
# Convert categorical (integer) data to binary

## Description

Convert an integer matrix to a binary (indicator) matrix.

## Usage

categorical2binary(data, maxval, missval)

## Arguments

* `data` Integer matrix to be converted
* `maxval` Theoretical maximum value observable in `data`
* `missval` Value to be considered missing

## Value

A tuple containing the following variables:

* `bindata` Original data matrix encoded as a binary (indicator) matrix
* `val` vector with unique values per MSA site
* `key` vector with indices of each value

## Example

If `data` consists of just the following three units

    0 2 1
    1 3 2
    2 4 0
    2 2 3

then `bindata` will be equal to

    0 0 1
    0 1 0
    1 0 0
    0 0 1
    0 1 0
    1 0 0
    0 1 0
    1 1 0
    0 0 1

while

    val = [1, 2, 1, 2, 3, 2, 4, 2, 3] (i.e. 12 123 24 23)
    key = [1, 1, 2, 2, 2, 3, 3, 4, 4] (i.e. 11 222 33 44)

`0` values (here missing data) are discarded.
"""
function categorical2binary(data::Matrix{T},
                            maxval::T,
                            missval::T) where T <: Integer
  # TOOPTIMIZE: traversing the matrices by row instead of by column
  (p, n) = size(data)
  m = 0

  # number of unique values per column
  v = zeros(Int, p)

  # maximum value actually observed in data
  M = c = zero(T)

  tmp = falses(Int(maxval))
  for row in 1:p
    fill!(tmp, false)

    for col in 1:n
      c = data[row, col]

      if (c < zero(T)) || (c > maxval)
        throw(KDomainError(string("Value outside the allowed range  at (row, ",
                                  "col) = (", row, ", ", col, ").")))
      end

      if (c != missval) && !tmp[c]
        tmp[c] = true
        v[row] += 1

        if c > M
          M = c
        end
      end
    end

    m += v[row]
  end

  bindata = zeros(UInt8, m, n)
  val = zeros(T, m)
  key = zeros(Int, m)

  i = 0
  j = 0
  tmp1 = falses(Int(M))
  tmp2 = zeros(UInt8, Int(M), n)
  for row in 1:p
    fill!(tmp1, false)
    fill!(tmp2, false)

    for col in 1:n
      c = data[row, col]

      if c != missval
        tmp1[c] = true
        tmp2[c, col] = 0x01
      end
    end

    j = i
    for h in 1:Int(M)
      if tmp1[h]
        j += 1

        val[j] = convert(T, h)
        key[j] = row
        for col in 1:n
          bindata[j, col] = tmp2[h, col]
        end
      end
    end

    i += v[row]
  end

  (bindata, val, key)
end

"""
# Convert categorical (string) data to binary

## Description

Convert a string matrix to a binary (indicator) matrix.

## Usage

categorical2binary(data, missval)

## Arguments

* `data` Integer matrix to be converted
* `missval` Value to be considered missing

## Value

A tuple containing the following variables:

* `bindata` Original data matrix encoded as a binary (indicator) matrix
* `val` vector with unique values per MSA site
* `key` vector with indices of each value

## Example

If `data` consists of just the following three units

      C A
    A G C
    C T
    C C G

then `bindata` will be equal to

    0 0 1
    0 1 0
    1 0 0
    0 0 1
    0 1 0
    1 0 0
    0 1 0
    1 1 0
    0 0 1

while

    val = ["A", "C", "A", "C", "G, "C", "T", "C", "G"] (i.e. AC ACG CT CG)
    key = [ 1,   1,   2,   2,   2,  3,   3,   4,   4 ] (i.e. 11 222 33 44)

` ` values (here missing data) are discarded.
"""
function categorical2binary(data::Matrix{String},
                            missval::String)
  # TOOPTIMIZE: traversing the matrices by row instead of by column
  (p, n) = size(data)
  m = 0

  # number of unique values per column
  v = zeros(Int, size(data, 1))

  for row in 1:p
    obs = sort(unique(filter(x -> x != missval, data[row, :])))
    v[row] = length(obs)
    m += v[row]
  end

  bindata = zeros(UInt8, m, n)
  val = Array{String}(undef, m)
  key = zeros(Int, m)

  j = 0
  for row in 1:p
    obs = sort(unique(filter(x -> x != missval, data[row, :])))

    for s in obs
      j += 1
      bindata[j, data[row, :] .== s] .= 0x01
      val[j] = s
      key[j] = row
    end
  end

  (bindata, val, key)
end
