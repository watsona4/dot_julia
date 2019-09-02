# This file is part of Kpax3. License is MIT.

# TODO: test normalizepartition, modifypartition, modifymerge, modifysplit,
#       modifyscramble

function test_partition_functions_initializepartition()
  ifile = "data/read_proper_aa.fasta"
  ofile = "../build/test"

  settings = Kpax3.KSettings(ifile, ofile)

  R = Kpax3.initializepartition(settings)

  @test isa(R, Vector{Int})
  @test minimum(R) >= 1
  @test maximum(R) <= 6

  R = Kpax3.initializepartition(settings, kset=2:3)

  @test isa(R, Vector{Int})
  @test minimum(R) >= 1
  @test maximum(R) <= 3

  (data, id, ref) = Kpax3.readfasta(ifile, true, UInt8['?', '*', '#', 'b', 'j', 'x', 'z'], 100000000, false, 0)

  n = size(data, 2)

  d = Kpax3.distaamtn84(data, ref)

  D = zeros(Float64, n, n)
  idx = 0
  for j in 1:(n - 1), i in (j + 1):n
    idx += 1
    D[i, j] = D[j, i] = d[idx]
  end

  x = Kpax3.AminoAcidData(settings)

  R = Kpax3.initializepartition(x.data, D, settings)

  @test isa(R, Vector{Int})
  @test minimum(R) >= 1
  @test maximum(R) <= 6

  R = Kpax3.initializepartition(x.data, D, settings, kset=2:3)

  @test isa(R, Vector{Int})
  @test minimum(R) >= 1
  @test maximum(R) <= 3

  nothing
end

test_partition_functions_initializepartition()

function test_partition_functions_encodepartition()
  R = zeros(Int, 6)
  S = [3; 3; 3; 2; 2; 1]

  Kpax3.encodepartition!(R, S)

  @test R == [1; 2; 3; 22; 23; 36]

  nothing
end

test_partition_functions_encodepartition()

function test_partition_functions_decodepartition()
  R = [1; 2; 3; 22; 23; 36]

  Kpax3.decodepartition!(R)

  @test R == [1; 1; 1; 4; 4; 6]

  nothing
end

test_partition_functions_decodepartition()
