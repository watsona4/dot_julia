# This file is part of Kpax3. License is MIT.

function readposteriork(fileroot::String)
  fp = string(fileroot, "_posterior_k.csv")
  d = DelimitedFiles.readdlm(fp, ',', String, header=true)

  len = size(d[1], 1)

  k = zeros(Int, len)
  pk = zeros(Float64, len)

  for i in 1:len
    k[i] = parse(Int, d[1][i, 1])
    pk[i] = parse(Float64, d[1][i, 2])
  end

  (k, pk)
end

function readposteriorP(fileroot::String)
  fp = string(fileroot, "_posterior_R.csv")
  d = DelimitedFiles.readdlm(fp, ',', String, header=true)

  len = size(d[1], 1)
  n = convert(Int, (1 + sqrt(1 + 8 * len)) / 2)

  id = fill("", n)
  P = ones(Float64, n, n)

  id[1] = d[1][1, 1]
  idx = 0
  for j in 1:(n - 1)
    id[j + 1] = d[1][j, 2]

    for i in (j + 1):n
      idx += 1
      P[i, j] = P[j, i] = parse(Float64, d[1][idx, 3])
    end
  end

  (id, P)
end

function readposteriorC(fileroot::String)
  fp = string(fileroot, "_posterior_C.csv")
  d = DelimitedFiles.readdlm(fp, ',', String, header=true)

  len = size(d[1], 1)

  site = zeros(Int, len)
  aa = fill("", len)
  freq = zeros(Float64, len)
  C = zeros(Float64, 3, len)

  for b in 1:len
    site[b] = parse(Int, d[1][b, 1])
    aa[b] = d[1][b, 2]
    freq[b] = parse(Float64, d[1][b, 3])
    C[1, b] = parse(Float64, d[1][b, 4])
    C[2, b] = parse(Float64, d[1][b, 5])
    C[3, b] = parse(Float64, d[1][b, 6])
  end

  (site, aa, freq, C)
end
