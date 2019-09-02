# This file is part of Kpax3. License is MIT.

function processchain(x::AminoAcidData,
                      fileroot::String)
  # open and close output files to check writing permissions
  # fail early if we can't write, saving the computational time required to
  # process the chain
  # use "append" for a non destructive operation
  fp = open(string(fileroot, "_posterior_k.csv"), "a")
  close(fp)

  fp = open(string(fileroot, "_posterior_R.csv"), "a")
  close(fp)

  fp = open(string(fileroot, "_posterior_C.csv"), "a")
  close(fp)

  n = zeros(Int, 1)
  m = zeros(Int, 1)
  N = zeros(Int, 1)

  k = zeros(Int, 1)

  h = 0

  fpR = open(string(fileroot, "_row_partition.bin"), "r")

  read!(fpR, n)
  read!(fpR, m)
  read!(fpR, N)

  R = zeros(Int, n[1])

  pk = zeros(Float64, n[1])
  pR = zeros(Float64, div(n[1] * (n[1] - 1), 2))

  T = 0
  try
    while !eof(fpR)
      read!(fpR, k)
      read!(fpR, R)

      pk[k[1]] += 1

      h = 0
      for i in 1:(n[1] - 1), j in (i + 1):n[1]
        h += 1
        pR[h] += float(R[i] == R[j])
      end

      T += 1
    end
  finally
    close(fpR)
  end

  if T != N[1]
    warn(string("Expecting ", N[1], " simulations but instead found ", T, "."))
  end

  pk /= T
  pR /= T

  fp = open(string(fileroot, "_posterior_k.csv"), "w")
  write(fp, "\"k\",\"p(k | x)\"\n")
  for g in 1:n[1]
    if pk[g] > 0.0
      write(fp, string(g, ",", pk[g], "\n"))
    end
  end
  close(fp)

  fp = open(string(fileroot, "_posterior_R.csv"), "w")
  write(fp, "\"Unit i\",\"Unit j\",\"p(i ~ j | x)\"\n")
  h = 0
  for i in 1:(n[1] - 1), j in (i + 1):n[1]
    h += 1
    write(fp, string("\"", x.id[i], "\",", "\"", x.id[j], "\",", pR[h], "\n"))
  end
  close(fp)

  fpC = open(string(fileroot, "_col_partition.bin"), "r")

  read!(fpC, n)
  read!(fpC, m)
  read!(fpC, N)

  C = zeros(UInt8, m[1])

  pC = zeros(Float64, 3, m[1])

  T = 0
  try
    while !eof(fpC)
      readbytes!(fpC, C, m[1])

      for b in 1:m[1]
        pC[C[b], b] += 1
      end

      T += 1
    end
  finally
    close(fpC)
  end

  if T != N[1]
    warn(string("Expecting ", N[1], " simulations but instead found ", T, "."))
  end

  pC /= T

  # estimate the probabilities of amino acids at each site
  #
  # Use a Dirichlet(1/J, ..., 1/J) as the prior distibution for the vector of
  # probabilities, where J is the total number of unique amino acids observed
  # at the current site. If y[j] is the count of amino acid j, then
  # a[j] = y[j] + 1 / J
  # is the corresponding parameter of the posterior probability.
  #
  # Posterior expected value is p = a / sum(a) = (y + 1 / J) / (n + 1)
  p = sum(float(x.data), dims=2)

  key = 1
  idxstart = 1
  a = 0.0
  count = 0.0
  for idxend in 1:m[1]
    if x.key[idxend] != key
      idx = idxstart:(idxend - 1)
      a = 1 / length(idx)

      for i in idx
        p[i] = (p[i] + a) / (n[1] + 1)
      end

      key += 1
      idxstart = idxend
      count = 0.0
    end

    count += p[idxend]
  end

  idx = idxstart:m[1]
  a = 1 / length(idx)

  for i in idx
    p[i] = (p[i] + a) / (n[1] + 1)
  end

  fp = open(string(fileroot, "_posterior_C.csv"), "w")
  write(fp, string("\"Site\",\"AminoAcid\",\"Proportion\",\"p('noise' | x)\",",
                   "\"p('weak signal' | x)\",\"p('strong signal' | x)\"\n"))

  isuint8 = eltype(x.ref) == UInt8

  polval = if isuint8
              UInt8('.')
            else
              "."
            end

  key = 0
  b = 1
  for j in 1:length(x.ref)
    if x.ref[j] == polval
      key += 1

      while (b <= m[1]) && (x.key[b] == key)
        write(fp, string(j, ",\"",
                        uppercase(isuint8 ? string(Char(x.val[b])) : x.val[b]),
                        "\",", p[b], ",", pC[1, b], ",", pC[2, b], ",",
                        pC[3, b], "\n"))
        b += 1
      end
    else
      write(fp, string(j, ",\"",
                       uppercase(isuint8 ? string(Char(x.ref[j])) : x.ref[j]),
                       "\",", 1.0, ",", 1.0, ",", 0.0, ",", 0.0, "\n"))
    end
  end
  close(fp)

  nothing
end

function savestate!(fpR::IOStream,
                    fpC::IOStream,
                    state::AminoAcidState)
  write(fpR, state.k)
  write(fpR, state.R)

  for b in 1:size(state.C, 2)
    write(fpC, state.C[state.cl[1], b] < 0x03 ? state.C[state.cl[1], b] : 0x03)
  end

  nothing
end
