# This file is part of Kpax3. License is MIT.

function kpax3Restimate(fileroot::String)
  (k, pk) = readposteriork(fileroot)
  (id, P) = readposteriorP(fileroot)

  n = length(id)

  D = 1.0 .- P

  R = zeros(Int, n)
  estimate = ones(Int, n)

  lossold = Inf
  lossnew = Inf
  niter = 0
  for g in k
    try
      copyto!(estimate, Clustering.kmedoids(D, g).assignments)
    catch
      StatsBase.sample!(1:g, estimate, replace=true)
      estimate[StatsBase.sample(1:n, g, replace=false)] .= collect(1:g)
    end

    niter = 0
    while niter < 100
      lossnew = loss_binder(estimate, P)

      if lossnew < lossold
        lossold = lossnew
        copyto!(R, estimate)
      end

      try
        copyto!(estimate, Clustering.kmedoids(D, g).assignments)
      catch
        StatsBase.sample!(1:g, estimate, replace=true)
        estimate[StatsBase.sample(1:n, g, replace=false)] .= collect(1:g)
      end

      niter += 1
    end
  end

  R
end

function kpax3estimate(x::AminoAcidData,
                       settings::KSettings)
  R = kpax3Restimate(settings.ofile)

  fpS = open(string(settings.ofile, "_settings.bin"), "r")

  tmp1 = zeros(Int, 3)
  read!(fpS, tmp1)

  n = tmp1[1]
  m = tmp1[2]
  N = tmp1[3]

  tmp2 = zeros(Float64, 6)
  read!(fpS, tmp2)

  α = tmp2[1]
  θ = tmp2[2]
  γ = [tmp2[3]; tmp2[4]; tmp2[5]]
  r = tmp2[6]

  close(fpS)

  op = copy(StatsBase.values(settings.op))

  settings = KSettings(settings.ifile, settings.ofile, settings.protein,
                       settings.miss, settings.misscsv, settings.l, α, θ, γ, r,
                       settings.maxclust, settings.maxunit, settings.verbose,
                       settings.verbosestep, settings.popsize,
                       settings.maxiter, settings.maxgap, settings.xrate,
                       settings.mrate, settings.T, settings.burnin,
                       settings.tstep, StatsBase.ProbabilityWeights(op))

  k = maximum(R)

  priorR = EwensPitman(α, θ)
  priorC = AminoAcidPriorCol(x.data, γ, r)

  AminoAcidState(x.data, R, priorR, priorC, settings)
end
