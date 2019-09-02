# This file is part of Kpax3. License is MIT.

function kpax3ga!(x::AminoAcidData,
                  population::AminoAcidStateList,
                  priorR::PriorRowPartition,
                  priorC::PriorColPartition,
                  settings::KSettings,
                  support::GASupport)
  if settings.verbose
    Printf.@printf("Initializing Genetic Algorithm... ")
  end

  # check if we can write to the backup file
  fp = open(settings.ofile, "w")
  close(fp)

  # elitism
  Nelite = max(1, ceil(Int, settings.popsize * 0.2))

  # randomization
  Nrand = Nelite + floor(Int, settings.popsize * 0.1)

  if ((settings.popsize - Nrand) % 2) != 0
    Nrand += 1
  end

  # initialize variables
  R = zeros(Int, support.n)

  i = 1
  maxk = 0
  idx = 0
  for i in 1:settings.popsize
    if population.state[i].k > maxk
      maxk = population.state[i].k
      idx = i
    end
  end

  beststate = copystate(population.state[population.rank[1]])

  newpopulation = AminoAcidStateList(settings.popsize, population.state[idx])

  if settings.verbose
    Printf.@printf("done\n")
    Printf.@printf("Current number of clusters: %d\n", beststate.k)
    Printf.@printf("Current log-posterior (plus a constant): %.4f\n",
                   beststate.logpp)
    Printf.@printf("Stochastic optimization is now running...\n")
  end

  iter = 0
  gap = 0
  keepgoing = true
  while keepgoing
    # copy the first Nelite best solutions without changing them
    i = 1
    while i <= Nelite
      copystate!(newpopulation.state[i], population.state[population.rank[i]])
      newpopulation.logpp[i] = population.logpp[population.rank[i]]
      i += 1
    end

    # now create Nrand random solutions starting from the best one
    while i <= Nrand
      copyto!(R, newpopulation.state[1].R)
      modifypartition!(R, newpopulation.state[1].k)

      newpopulation.state[i] = AminoAcidState(x.data, R, priorR, priorC,
                                              settings)
      newpopulation.logpp[i] = newpopulation.state[i].logpp

      i += 1
    end

    while i <= settings.popsize
      (i1, i2) = selection(population.logpp)

      if rand() <= settings.xrate
        crossover!(population.state[i1].R, population.state[i2].R, support)
      else
        copyto!(support.oi.R, population.state[i1].R)
        copyto!(support.oi.v, population.state[i1].v)

        copyto!(support.oj.R, population.state[i2].R)
        copyto!(support.oj.v, population.state[i2].v)
      end

      mutation!(support.oi, settings.mrate)
      mutation!(support.oj, settings.mrate)

      updatestate!(newpopulation.state[i], x.data, support.oi.R, priorR,
                   priorC, settings)
      updatestate!(newpopulation.state[i + 1], x.data, support.oj.R, priorR,
                   priorC, settings)

      newpopulation.logpp[i] = newpopulation.state[i].logpp
      newpopulation.logpp[i + 1] = newpopulation.state[i + 1].logpp

      i += 2
    end

    sortperm!(newpopulation.rank, newpopulation.logpp, rev=true,
              initialized=true)

    copystatelist!(population, newpopulation, settings.popsize)

    if population.logpp[population.rank[1]] >  beststate.logpp
      copystate!(beststate, population.state[population.rank[1]])
      gap = 0

      if settings.verbose
        Printf.@printf("Found a better solution! ")
        Printf.@printf("Log-posterior (plus a constant) for %d clusters: %.4f\n",
                       beststate.k, beststate.logpp)
      end
    else
      gap += 1
      keepgoing = (gap <= settings.maxgap)
    end

    iter += 1

    if iter < settings.maxiter
      if iter % settings.verbosestep == 0
        fp = open(settings.ofile, "w")
        for i in 1:support.n
          write(fp, "\"$(x.id[i])\",$(beststate.R[i])\n")
        end
        close(fp)

        if settings.verbose
          println("Step ", iter, " done")
        end
      end
    else
      keepgoing = false
    end
  end

  beststate
end

function kpax3ga(partition::Vector{Int},
                 settings::KSettings)
  x = AminoAcidData(settings)
  (m, n) = size(x.data)

  R = normalizepartition(partition, n)
  k = maximum(R)

  maxclust = min(n, max(k, settings.maxclust))

  priorR = EwensPitman(settings.α, settings.θ)
  priorC = AminoAcidPriorCol(x.data, settings.γ, settings.r)

  population = AminoAcidStateList(x.data, R, priorR, priorC, settings)

  support = GASupport(m, n)

  kpax3ga!(x, population, priorR, priorC, settings, support)
end

function kpax3ga(x::AminoAcidData,
                 partition::Vector{Int},
                 settings::KSettings)
  (m, n) = size(x.data)

  R = normalizepartition(partition, n)
  k = maximum(R)

  maxclust = min(n, max(k, settings.maxclust))

  priorR = EwensPitman(settings.α, settings.θ)
  priorC = AminoAcidPriorCol(x.data, settings.γ, settings.r)

  population = AminoAcidStateList(x.data, R, priorR, priorC, settings)

  support = GASupport(m, n)

  kpax3ga!(x, population, priorR, priorC, settings, support)
end

function kpax3ga(partition::String,
                 settings::KSettings)
  x = AminoAcidData(settings)
  (m, n) = size(x.data)

  R = normalizepartition(partition, x.id)
  k = maximum(R)

  maxclust = min(n, max(k, settings.maxclust))

  priorR = EwensPitman(settings.α, settings.θ)
  priorC = AminoAcidPriorCol(x.data, settings.γ, settings.r)

  population = AminoAcidStateList(x.data, R, priorR, priorC, settings)

  support = GASupport(m, n)

  kpax3ga!(x, population, priorR, priorC, settings, support)
end

function kpax3ga(x::AminoAcidData,
                 partition::String,
                 settings::KSettings)
  (m, n) = size(x.data)

  R = normalizepartition(partition, x.id)
  k = maximum(R)

  maxclust = min(n, max(k, settings.maxclust))

  priorR = EwensPitman(settings.α, settings.θ)
  priorC = AminoAcidPriorCol(x.data, settings.γ, settings.r)

  population = AminoAcidStateList(x.data, R, priorR, priorC, settings)

  support = GASupport(m, n)

  kpax3ga!(x, population, priorR, priorC, settings, support)
end
