# This file is part of Kpax3. License is MIT.

function test_write_results()
  ifile = "data/read_proper_aa.fasta"
  ofile = "../build/test"
  partition = "data/output_fasta_proper_aa_partition.csv"

  settings = Kpax3.KSettings(ifile, ofile, gamma=[0.4; 0.35; 0.25])

  x = Kpax3.AminoAcidData(settings)

  R = Kpax3.normalizepartition(partition, x.id)
  k = maximum(R)

  priorR = Kpax3.EwensPitman(settings.α, settings.θ)
  priorC = Kpax3.AminoAcidPriorCol(x.data, settings.γ, settings.r)

  state = Kpax3.AminoAcidState(x.data, R, priorR, priorC, settings)

  Kpax3.writeresults(x, state, "../build/test_results", what=4)

  y1 = read("../build/test_results_partition.csv", String)
  y2 = parse(Float64, strip(read("../build/test_results_logposterior_value.txt", String)))
  y3 = read("../build/test_results_attributes.csv", String)
  y4 = read("../build/test_results_characteristic.csv", String)
  y5 = read("../build/test_results_dataset.txt", String)

  @test y1 == read(partition, String)
  @test isapprox(y2, state.logpp, rtol=ε)
  @test y3 == read("data/output_fasta_proper_aa_attributes.csv", String)
  @test y4 == read("data/output_fasta_proper_aa_characteristic.csv", String)
  @test y5 == read("data/output_fasta_proper_aa_dataset.txt", String)

  nothing
end

test_write_results()
