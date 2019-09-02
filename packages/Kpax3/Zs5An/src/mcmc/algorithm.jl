# This file is part of Kpax3. License is MIT.

function kpax3mcmc!(data::Matrix{UInt8},
                    priorR::PriorRowPartition,
                    priorC::PriorColPartition,
                    settings::KSettings,
                    support::MCMCSupport,
                    state::AminoAcidState)
  fpS = open(string(settings.ofile, "_settings.bin"), "w")
  fpR = open(string(settings.ofile, "_row_partition.bin"), "w")
  fpC = open(string(settings.ofile, "_col_partition.bin"), "w")

  # total number of states that will be saved
  N = fld(settings.T, settings.tstep)

  # effective number of simulations
  T = settings.tstep * N

  # indices of units i and j
  ij = zeros(Int, 2)

  # neighbour indices
  neighbours = zeros(Int, support.n)

  try
    write(fpS, support.n)
    write(fpS, support.m)
    write(fpS, N)
    write(fpS, settings.α)
    write(fpS, settings.θ)
    write(fpS, settings.γ[1])
    write(fpS, settings.γ[2])
    write(fpS, settings.γ[3])
    write(fpS, settings.r)
  finally
    close(fpS)
  end

  try
    write(fpR, support.n)
    write(fpR, support.m)
    write(fpR, N)

    write(fpC, support.n)
    write(fpC, support.m)
    write(fpC, N)

    if settings.burnin > 0
      if settings.verbose
        println("Starting burnin phase...")
      end

      # sample which operators we are going to use
      operator = StatsBase.sample(UInt8[1; 2; 3], settings.op, settings.burnin)

      for t in 1:settings.burnin
        if operator[t] == 0x01
          splitmerge!(ij, neighbours, data, priorR, priorC, settings, support,
                      state)
        elseif operator[t] == 0x02
          gibbs!(data, priorR, priorC, settings, support, state)
        else
          biased_random_walk!(data, priorR, priorC, settings, support, state)
        end

        sampleC!(priorC, state)

        if settings.verbose && (t % settings.verbosestep == 0)
          println("Burnin: step ", t, " done.")
        end
      end

      if settings.verbose
        println("Burnin phase completed.")
      end
    end

    if settings.verbose
      println("Starting collecting samples...")
    end

    operator = StatsBase.sample(UInt8[1; 2; 3], settings.op, T)

    for t in 1:T
      if operator[t] == 0x01
        splitmerge!(ij, neighbours, data, priorR, priorC, settings, support,
                    state)
      elseif operator[t] == 0x02
        gibbs!(data, priorR, priorC, settings, support, state)
      else
        biased_random_walk!(data, priorR, priorC, settings, support, state)
      end

      sampleC!(priorC, state)

      if t % settings.tstep == 0
        savestate!(fpR, fpC, state)
      end

      if settings.verbose && (t % settings.verbosestep == 0)
        flush(fpR)
        flush(fpC)
        println("Step ", t, " done.")
      end
    end

    if settings.verbose
      println("Markov Chain simulation complete.")
    end
  finally
    close(fpR)
    close(fpC)
  end

  nothing
end

function kpax3mcmc(settings::KSettings)
  if settings.verbose
    Printf.@printf("Computing pairwise distances... ")
  end

  tmp = zeros(UInt8, length(settings.miss))
  idx = 0
  for c in 1:length(settings.miss)
    if settings.miss[c] != UInt8('-')
      idx += 1
      tmp[idx] = settings.miss[c]
    end
  end

  miss = if idx > 0
           copyto!(zeros(UInt8, idx), 1, tmp, 1, idx)
         else
           zeros(UInt8, 1)
         end

  (data, id, ref) = readfasta(settings.ifile, settings.protein, miss,
                              settings.l, false, 0)

  n = size(data, 2)

  d = if settings.protein
        distaamtn84(data, ref)
      else
        distntmtn93(data, ref)
      end

  D = zeros(Float64, n, n)
  idx = 1
  for j in 1:(n - 1), i in (j + 1):n
    D[i, j] = D[j, i] = d[idx]
    idx += 1
  end

  if settings.verbose
    Printf.@printf("done.\n")
  end

  # expected number of cluster approximately between cbrt(n) and sqrt(n)
  g = ceil(Int, n^(2 / 5))
  kset = max(1, g - 20):min(n, g + 20)

  x = AminoAcidData(settings)
  (m, n) = size(x.data)

  priorR = EwensPitman(settings.α, settings.θ)
  priorC = AminoAcidPriorCol(x.data, settings.γ, settings.r)

  state = initializestate(x.data, D, kset, priorR, priorC, settings)

  support = MCMCSupport(state, priorC)

  kpax3mcmc!(x.data, priorR, priorC, settings, support, state)

  if settings.verbose
    Printf.@printf("Processing Markov Chain output... ")
  end

  processchain(x, settings.ofile)

  if settings.verbose
    Printf.@printf("done.\n")
  end

  nothing
end

function kpax3mcmc(x::AminoAcidData,
                   partition::Vector{Int},
                   settings::KSettings)
  (m, n) = size(x.data)

  R = normalizepartition(partition, n)

  v = zeros(Int, n)
  g = 0
  k = 0
  u = 0
  for a in 1:n
    g = R[a]

    if v[g] == 0
      k += 1
    end

    v[g] += 1

    if v[g] > u
      u = v[g]
    end
  end

  maxclust = min(n, max(k, settings.maxclust))
  maxunit = min(n, max(u, settings.maxunit))

  priorR = EwensPitman(settings.α, settings.θ)
  priorC = AminoAcidPriorCol(x.data, settings.γ, settings.r)

  state = AminoAcidState(x.data, R, priorR, priorC, settings)

  support = MCMCSupport(state, priorC)

  kpax3mcmc!(x.data, priorR, priorC, settings, support, state)

  if settings.verbose
    Printf.@printf("Processing Markov Chain output... ")
  end

  processchain(x, settings.ofile)

  if settings.verbose
    Printf.@printf("done.\n")
  end

  nothing
end

function kpax3mcmc(x::AminoAcidData,
                   partition::String,
                   settings::KSettings)
  (m, n) = size(x.data)

  R = normalizepartition(partition, x.id)

  v = zeros(Int, n)
  g = 0
  k = 0
  u = 0
  for a in 1:n
    g = R[a]

    if v[g] == 0
      k += 1
    end

    v[g] += 1

    if v[g] > u
      u = v[g]
    end
  end

  maxclust = min(n, max(k, settings.maxclust))
  maxunit = min(n, max(u, settings.maxunit))

  priorR = EwensPitman(settings.α, settings.θ)
  priorC = AminoAcidPriorCol(x.data, settings.γ, settings.r)

  state = AminoAcidState(x.data, R, priorR, priorC, settings)

  support = MCMCSupport(state, priorC)

  kpax3mcmc!(x.data, priorR, priorC, settings, support, state)

  if settings.verbose
    Printf.@printf("Processing Markov Chain output... ")
  end

  processchain(x, settings.ofile)

  if settings.verbose
    Printf.@printf("done.\n")
  end

  nothing
end

function splitmerge!(ij::Vector{Int},
                     neighbours::Vector{Int},
                     data::Matrix{UInt8},
                     priorR::PriorRowPartition,
                     priorC::PriorColPartition,
                     settings::KSettings,
                     support::MCMCSupport,
                     state::AminoAcidState)
  # cluster founders (units i and j)
  StatsBase.sample!(1:support.n, ij, replace=false, ordered=false)

  # clusters of i and j respectively
  gi = state.R[ij[1]]
  gj = state.R[ij[2]]

  # total number of neighbours
  S = 0

  # generic unit
  u = 0

  if gi == gj
    for l in 1:state.v[gi]
      u = state.unit[gi][l]
      if (u != ij[1]) && (u != ij[2])
        S += 1
        neighbours[S] = u
      end
    end

    shuffleunits!(neighbours, S)

    split!(ij, neighbours, S, data, priorR, priorC, settings, support, state)
  else
    for l in 1:state.v[gi]
      u = state.unit[gi][l]
      if u != ij[1]
        S += 1
        neighbours[S] = u
      end
    end

    for l in 1:state.v[gj]
      u = state.unit[gj][l]
      if u != ij[2]
        S += 1
        neighbours[S] = u
      end
    end

    shuffleunits!(neighbours, S)

    merge!(ij, neighbours, S, data, priorR, priorC, settings, support, state)
  end

  nothing
end
