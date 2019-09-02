# This file is part of Kpax3. License is MIT.

function test_plotk()
  (k, pk) = Kpax3.readposteriork("../build/mcmc_6")
  p = Kpax3.kpax3plotk(k, pk, xticks=[1; 2; 3; 4; 5; 6])

  Plots.png(p, "../build/MCMC_posterior_k.png")

  nothing
end

test_plotk()

function test_plotc()
  (site, aa, freq, C) = Kpax3.readposteriorC("../build/mcmc_6")

  p = Kpax3.kpax3plotc(site, freq, C)

  Plots.png(p, "../build/MCMC_posterior_column_classifier.png")

  nothing
end

test_plotc()

function test_plotd()
  settings = Kpax3.KSettings("data/mcmc_6.fasta", "../build/tmp")
  x = Kpax3.AminoAcidData(settings)
  state = Kpax3.optimumstate(x, "data/mcmc_6.csv", settings)

  p = Kpax3.kpax3plotd(x, state, clusterorder=[4; 2; 1; 3],
                       clusterlabel=["d"; "b"; "a"; "c"])

  Plots.png(p, "../build/MCMC_posterior_dataset.png")

  nothing
end

test_plotd()

function test_plotp()
  (id, P) = Kpax3.readposteriorP("../build/mcmc_6")
  R = Kpax3.normalizepartition("data/mcmc_6.csv", id)

  p = Kpax3.kpax3plotp(R, P, clusterorder=[4; 2; 1; 3],
                       clusterlabel=["d"; "b"; "a"; "c"])

  Plots.png(p, "../build/MCMC_posterior_probability_matrix.png")

  nothing
end

test_plotp()

function test_plottrace()
  (entropy_R, avgd_R) = Kpax3.traceR("../build/mcmc_6", maxlag=50)
  (entropy_C, avgd_C) = Kpax3.traceC("../build/mcmc_6", maxlag=50)

  p = Kpax3.kpax3plottrace(entropy_R, maxlag=50, main="Trace")
  q = Kpax3.kpax3plottrace(entropy_C, maxlag=50, main="Trace")

  Plots.png(p, "../build/MCMC_posterior_trace_R.png")
  Plots.png(q, "../build/MCMC_posterior_trace_C.png")

  nothing
end

test_plottrace()

function test_plotdensity()
  (entropy_R, avgd_R) = Kpax3.traceR("../build/mcmc_6", maxlag=50)
  (entropy_C, avgd_C) = Kpax3.traceC("../build/mcmc_6", maxlag=50)

  p = Kpax3.kpax3plotdensity(entropy_R, maxlag=50, main="Density")
  q = Kpax3.kpax3plotdensity(entropy_C, maxlag=50, main="Density")

  Plots.png(p, "../build/MCMC_posterior_density_R.png")
  Plots.png(q, "../build/MCMC_posterior_density_C.png")

  nothing
end

test_plotdensity()

function test_plotjump()
  (entropy_R, avgd_R) = Kpax3.traceR("../build/mcmc_6", maxlag=50)
  (entropy_C, avgd_C) = Kpax3.traceC("../build/mcmc_6", maxlag=50)

  p = Kpax3.kpax3plotjump(avgd_R, main="Jump distance")
  q = Kpax3.kpax3plotjump(avgd_C, main="Jump distance")

  Plots.png(p, "../build/MCMC_posterior_jump_R.png")
  Plots.png(q, "../build/MCMC_posterior_jump_C.png")

  nothing
end

test_plotjump()
