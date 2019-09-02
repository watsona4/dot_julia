# This file is part of Kpax3. License is MIT.

function writeresults(x::KData,
                      state::State,
                      file::String;
                      what::Int=1,
                      verbose::Bool=false)
  dirpath = dirname(file)
  if !isdir(dirpath)
    mkpath(dirpath)
  end

  fp = open("$(file)_partition.csv", "w")
  for i in 1:size(x.data, 2)
    write(fp, "\"$(x.id[i])\",$(state.R[i])\n")
  end
  close(fp)

  write("$(file)_logposterior_value.txt",
        string(state.logpR + state.logpC[1] + state.loglik, "\n"))

  if verbose
    println("Partition has been written to file: $(file)_partition.csv")
    println("Log posterior probability (minus a constant) has been written ",
            "to file: $(file)_logposterior.txt")
  end

  if what >= 2
    writeattributes(x, state, file, verbose)

    if what >= 3
      V = writecvalues(x, state, file, verbose)

      if what >= 4
        writedataset(x, state, file, verbose, V)
      end
    end
  end

  nothing
end

function writeattributes(x::KData,
                         state::State,
                         file::String,
                         verbose::Bool)
  (m, n) = size(x.data)
  M = length(x.ref)

  isuint8 = eltype(x.ref) == UInt8

  polval = if isuint8
              UInt8('.')
            else
              "."
            end

  # attributes
  C = ones(UInt8, state.k, M)

  # column index in x.key
  s = 0

  # column indices in state.C
  t = 1
  b = 1

  # temporary value
  v = 0x01

  for j in 1:M
    if x.ref[j] == polval
      s += 1
      b = t
      v = 0x01

      while (b <= m) && (x.key[b] == s)
        if state.C[state.cl[1], b] > v
          v = state.C[state.cl[1], b]
        end
        b += 1
      end

      if v > 0x02
        for u in t:(b - 1), l in 1:state.k
          if state.C[state.cl[l], u] > C[l, j]
            C[l, j] = state.C[state.cl[l], u]
          end
        end
      elseif v == 0x02
        for l in 1:state.k
          C[l, j] = 0x02
        end
      end

      t = b
    end
  end

  fp = open("$(file)_attributes.csv", "w")
  for l in 1:(state.k - 1)
    write(fp, string("\"Cluster ", l, "\","))
  end
  write(fp, string("\"Cluster ", state.k, "\"\n"))

  for j in 1:M
    for l in 1:(state.k - 1)
      write(fp, string(Int(C[l, j]), ","))
    end
    write(fp, string(Int(C[state.k, j]), "\n"))
  end
  close(fp)

  if verbose
    println("Attributes have been written to file: $(file)_attributes.csv")
  end

  nothing
end

function writecvalues(x::KData,
                      state::State,
                      file::String,
                      verbose::Bool)
  (m, n) = size(x.data)
  M = length(x.ref)

  isuint8 = eltype(x.ref) == UInt8

  polval = if isuint8
              UInt8('.')
            else
              "."
            end

  # characteristic values
  V = fill(" ", (state.k, M))

  # column index in x.key
  s = 0

  # column indices in state.C
  t = 1
  b = 1

  # temporary values
  v = 0x01
  z = 0
  flag = false

  fp = open("$(file)_characteristic.csv", "w")
  write(fp, "\"Site\",")
  for l in 1:(state.k - 1)
    write(fp, string("\"Cluster ", l, "\","))
  end
  write(fp, string("\"Cluster ", state.k, "\"\n"))

  for j in 1:M
    if x.ref[j] == polval
      s += 1
      b = t
      v = 0x01

      while (b <= m) && (x.key[b] == s)
        if state.C[state.cl[1], b] > v
          v = state.C[state.cl[1], b]
        end
        b += 1
      end

      if v > 0x02
        write(fp, string(j, ","))

        for l in 1:(state.k - 1)
          z = t
          flag = false

          while !flag && z < b
            flag = state.C[state.cl[l], z] == 0x04
            z += 1
          end

          if flag
            V[l, j] = uppercase(isuint8 ?
                                string(Char(x.val[z - 1])) :
                                x.val[z - 1])
            write(fp, string("\"", V[l, j], "\","))
          else
            write(fp, ",")
          end
        end

        z = t
        flag = false

        while !flag && z < b
          flag = state.C[state.cl[state.k], z] == 0x04
          z += 1
        end

        if flag
          V[state.k, j] = uppercase(isuint8 ?
                                    string(Char(x.val[z - 1])) :
                                    x.val[z - 1])
          write(fp, string("\"", V[state.k, j], "\"\n"))
        else
          write(fp, "\n")
        end
      end

      t = b
    end
  end
  close(fp)

  if verbose
    println("Characteristic values have been written to file: ",
            "$(file)_characteristic.csv")
  end

  V
end

function writedataset(x::KData,
                      state::State,
                      file::String,
                      verbose::Bool,
                      V::Matrix{String})
  (m, n) = size(x.data)
  M = length(x.ref)

  isuint8 = eltype(x.ref) == UInt8

  polval = if isuint8
              UInt8('.')
            else
              "."
            end

  # reconstruct original dataset
  D = fill(" ", (M, n))

  # column index in x.key
  s = 0

  # column indices in state.C
  t = 1
  b = 1

  # temporary values
  g = 0

  for a in 1:n
    s = 0
    t = 1
    g = state.R[a]

    for j in 1:M
      if x.ref[j] == polval
        s += 1
        b = t

        while (b <= m) && (x.key[b] == s)
          if x.data[b, a] == 0x01
            D[j, a] = (state.C[g, b] == 0x04) ?
                      uppercase(isuint8 ? string(Char(x.val[b])) : x.val[b]) :
                      lowercase(isuint8 ? string(Char(x.val[b])) : x.val[b])
          end
          b += 1
        end

        t = b
      end
    end
  end

  fp = open("$(file)_dataset.txt", "w")
  for l in 1:(state.k - 1)
    for j in 1:M
      write(fp, V[l, j])
    end
    write(fp, "\n")

    for i in 1:state.v[state.cl[l]]
      a = state.unit[state.cl[l]][i]
      for j in 1:M
        write(fp, D[j, a])
      end
      write(fp, string(" ; ", x.id[a], "\n"))
    end

    write(fp, "\n")
  end

  for j in 1:M
    write(fp, V[state.k, j])
  end
  write(fp, "\n")

  for i in 1:state.v[state.cl[state.k]]
    a = state.unit[state.cl[state.k]][i]
    for j in 1:M
      write(fp, D[j, a])
    end
    write(fp, string(" ; ", x.id[a], "\n"))
  end
  close(fp)

  nothing
end
