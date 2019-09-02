# This file is part of Kpax3. License is MIT.

abstract type StateList end

mutable struct AminoAcidStateList <: StateList
  state::Vector{AminoAcidState}
  logpp::Vector{Float64}
  rank::Vector{Int}
end

function AminoAcidStateList(data::Matrix{UInt8},
                            partition::Vector{Int},
                            priorR::PriorRowPartition,
                            priorC::AminoAcidPriorCol,
                            settings::KSettings)
  state = Array{AminoAcidState}(undef, settings.popsize)
  logpp = zeros(Float64, settings.popsize)
  rank = Int[i for i in 1:settings.popsize]

  state[1] = AminoAcidState(data, partition, priorR, priorC, settings)
  logpp[1] = state[1].logpp

  if settings.verbose
    Printf.@printf("Creating initial population... ")
  end

  R = zeros(Int, size(data, 2))
  for i in 2:settings.popsize
    copyto!(R, partition)
    modifypartition!(R, state[1].k)
    state[i] = AminoAcidState(data, R, priorR, priorC, settings)
    logpp[i] = state[i].logpp
  end

  sortperm!(rank, logpp, rev=true, initialized=true)

  if settings.verbose
    Printf.@printf("done\n")
  end

  AminoAcidStateList(state, logpp, rank)
end

function AminoAcidStateList(popsize::Int,
                            s::AminoAcidState)
  state = Array{AminoAcidState}(undef, popsize)
  logpp = zeros(Float64, popsize)
  rank = Int[i for i in 1:popsize]

  for i in 1:popsize
    state[i] = copystate(s)
    logpp[i] = state[i].logpp
  end

  AminoAcidStateList(state, logpp, rank)
end

function copystatelist!(dest::AminoAcidStateList,
                        src::AminoAcidStateList,
                        popsize::Int)
  for i in 1:popsize
    copystate!(dest.state[i], src.state[src.rank[i]])
    dest.logpp[i] = src.logpp[src.rank[i]]
    dest.rank[i] = i
  end

  nothing
end
