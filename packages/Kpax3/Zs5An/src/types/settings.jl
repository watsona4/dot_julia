# This file is part of Kpax3. License is MIT.

"""
# User defined settings for a Kpax3 run

## Description

## Fields

"""
struct KSettings
  ifile::String
  ofile::String
  # Common parameters
  protein::Bool
  miss::Vector{UInt8}
  misscsv::Vector{String}
  l::Int
  α::Real
  θ::Real
  γ::Vector{Float64}
  r::Float64
  maxclust::Int
  maxunit::Int
  verbose::Bool
  verbosestep::Int
  # Genetic Algorithm parameters
  popsize::Int
  maxiter::Int
  maxgap::Int
  xrate::Float64
  mrate::Float64
  # MCMC parameters
  T::Int
  burnin::Int
  tstep::Int
  op::StatsBase.ProbabilityWeights
end

function KSettings(ifile::String,
                   ofile::String;
                   protein::Bool=true,
                   miss::Vector{UInt8}=zeros(UInt8, 0),
                   misscsv::Vector{String}=Array{String}(undef, 0),
                   l::Int=100000000,
                   alpha::Real=0.5,
                   theta::Real=-0.25,
                   gamma::Vector{Float64}=[0.6; 0.35; 0.05],
                   r::Float64=log(0.001) / log(0.95),
                   maxclust::Int=500,
                   maxunit::Int=500,
                   verbose::Bool=false,
                   verbosestep::Int=1000,
                   popsize::Int=20,
                   maxiter::Int=20000,
                   maxgap::Int=5000,
                   xrate::Float64=0.9,
                   mrate::Float64=0.005,
                   T::Int=100000,
                   burnin::Int=10000,
                   tstep::Int=1,
                   op::Vector{Float64}=[0.5; 0.0; 0.5])
  # open files and immediately close them. We do this to throw a proper Julia
  # standard exception if something is wrong
  f = open(ifile, "r")
  close(f)

  dirpath = dirname(ofile)
  if !isdir(dirpath)
    mkpath(dirpath)
  end

  #=
  f = open(string(ofile, "_settings.bin"), "a")
  close(f)

  f = open(string(ofile, "_row_partition.bin"), "a")
  close(f)

  f = open(string(ofile, "_col_partition.bin"), "a")
  close(f)
  =#

  if length(miss) == 0
    miss = if protein
             UInt8['?', '*', '#', '-', 'b', 'j', 'x', 'z']
           else
             UInt8['?', '*', '#', '-', 'b', 'd', 'h', 'k', 'm', 'n', 'r', 's',
                   'v', 'w', 'x', 'y', 'j', 'z']
           end
  else
    if length(miss) == 1
      if miss[1] != UInt8(0)
        if UInt8(0) < miss[1] < UInt8(128)
          if UInt8(64) < miss[1] < UInt8(91)
            # convert to lowercase
            miss[1] += UInt8(32)
          end
        else
          throw(KDomainError(string("Value 'miss[1]' is not in the range ",
                                    "[1, ..., 127]: ", Int(miss[1]), ".")))
        end
      end
    else
      for i in 1:length(miss)
        if UInt8(0) < miss[i] < UInt8(128)
          if UInt8(64) < miss[i] < UInt8(91)
            # convert to lowercase
            miss[i] += UInt8(32)
          end
        else
          throw(KDomainError(string("Value 'miss[", i, "]' is not in the ",
                                    "range [1, ..., 127]: ",
                                    Int(miss[i]), ".")))
        end
      end
    end
  end

  if length(misscsv) == 0
    misscsv = [""]
  elseif !("" in misscsv)
    insert!(misscsv, 1, "")
  end

  if l < 1
    throw(KDomainError("Argument 'l' is not positive."))
  end

  if length(gamma) != 3
    throw(KInputError("Argument 'gamma' does not have length 3."))
  elseif gamma[1] < 0
    throw(KDomainError("Argument 'gamma[1]' is negative."))
  elseif gamma[2] < 0
    throw(KDomainError("Argument 'gamma[2]' is negative."))
  elseif gamma[3] < 0
    throw(KDomainError("Argument 'gamma[3]' is negative."))
  end

  if r <= 0.0
    throw(KDomainError("Argument 'r' is not positive."))
  end

  if maxclust < 1
    throw(KDomainError("Argument maxclust is lesser than 1."))
  end

  if maxunit < 1
    throw(KDomainError("Argument maxunit is lesser than 1."))
  end

  if verbosestep < 0
    throw(KDomainError("Argument 'verbosestep' is negative."))
  end

  # disable status reports if verbosestep is not positive
  verbose = verbose && (verbosestep > 0)

  if popsize < 4
    throw(KDomainError("Argument 'popsize' is lesser than 4."))
  end

  if maxiter < 1
    throw(KDomainError("Argument 'maxiter' is lesser than 1."))
  end

  if maxgap < 0
    throw(KDomainError("Argument 'maxgap' is lesser than 1."))
  end

  if !(0 <= xrate <= 1)
    throw(KDomainError("Argument 'xrate' is not in the range [0, 1]."))
  end

  if !(0 <= mrate <= 1)
    throw(KDomainError("Argument 'mrate' is not in the range [0, 1]."))
  end

  if T < 1
    throw(KDomainError("Argument 'T' is lesser than 1."))
  end

  if burnin < 0
    throw(KDomainError("Argument 'burnin' is negative."))
  end

  if tstep < 0
    throw(KDomainError("Argument 'tstep' is negative."))
  end

  if length(op) != 3
    throw(KInputError("Argument 'op' does not have length 3."))
  elseif op[1] < 0
    throw(KDomainError("Argument 'op[1]' is negative."))
  elseif op[2] < 0
    throw(KDomainError("Argument 'op[2]' is negative."))
  elseif op[3] < 0
    throw(KDomainError("Argument 'op[3]' is negative."))
  end

  KSettings(ifile, ofile, protein, miss, misscsv, l, alpha, theta, gamma, r,
            maxclust, maxunit, verbose, verbosestep, popsize, maxiter, maxgap,
            xrate, mrate, T, burnin, tstep, StatsBase.ProbabilityWeights(op))
end
