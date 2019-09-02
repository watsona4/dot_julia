# This file is part of Kpax3. License is MIT.

# suppose we
# a) split a cluster with 15 units into two clusters of 8 and 7 units
#    respectively, moving from k = 5 to k = 6
# b) move a unit from a cluster with 15 units to a new cluster (split)
# c) move a unit from a cluster with 15 units to another cluster with 7 units

function test_mcmc_partition_ratios()
  ifile = "data/read_proper_aa.fasta"
  ofile = "../build/test"

  settings = Kpax3.KSettings(ifile, ofile)

  x = Kpax3.AminoAcidData(settings)

  priorR = Kpax3.EwensPitman(settings.α, settings.θ)
  priorC = Kpax3.AminoAcidPriorCol(x.data, settings.γ, settings.r)

  state = Kpax3.AminoAcidState(x.data, [1; 1; 1; 1; 1; 1], priorR, priorC, settings)
  support = Kpax3.MCMCSupport(state, priorC)

  support.vi = 8
  support.vj = 7

  for (α, θ) in ((0.4, -0.3), (0.4, 0.0), (0.4, 2.1), (0.0, 2.1), (-2.4, 10))
    ep = Kpax3.EwensPitman(α, θ)

    lr1 = Kpax3.logdPriorRow(50, 6, [22;  8; 7; 5; 1; 7], ep) - Kpax3.logdPriorRow(50, 5, [22; 15; 7; 5; 1], ep)

    Kpax3.logratiopriorrowsplit!(6, ep, support)
    @test isapprox(support.lograR, lr1, atol=ε)

    Kpax3.logratiopriorrowmerge!(5, ep, support)
    @test isapprox(support.lograR, -lr1, atol=ε)

    lr2 = Kpax3.logdPriorRow(50, 6, [22; 14; 7; 5; 1; 1], ep) - Kpax3.logdPriorRow(50, 5, [22; 15; 7; 5; 1], ep)

    @test isapprox(Kpax3.logratiopriorrowsplit(6, 15, ep), lr2, atol=ε)
    @test isapprox(Kpax3.logratiopriorrowmerge(5, 14, ep), -lr2, atol=ε)

    lr3 = Kpax3.logdPriorRow(50, 5, [22; 14; 8; 5; 1], ep) - Kpax3.logdPriorRow(50, 5, [22; 15; 7; 5; 1], ep)

    @test isapprox(Kpax3.logratiopriorrowmove(15, 7, ep), lr3, atol=ε)
  end

  nothing
end

test_mcmc_partition_ratios()
