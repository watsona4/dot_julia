# This file is part of Kpax3. License is MIT.

# the following code has been modified from
# http://thirld.com/blog/2015/05/30/julia-profiling-cheat-sheet/

#=
# do not forget to run julia with --track-allocation=user
# to view results
using ProfileView
f = open("build/profile.bin", "r")
r = deserialize(f);
ProfileView.view(r[1], lidict=r[2])
=#
function benchmark()
  include("src/boot.jl")

  settings = KSettings("test/data/mcmc_6.fasta", "test/data/mcmc_6",
                       α=0.5, θ=-0.25, γ=[0.6; 0.35; 0.05],
                       r=log(0.001)/log(0.95), maxclust=1, maxunit=1,
                       verbose=false, verbosestep=100000, popsize=50,
                       xrate=0.9, mrate=0.05, T=1000000, burnin=500000,
                       tstep=1, op=[0.6; 0.3; 0.1], λs1=1.0, λs2=1.0,
                       parawm=5.0)

  x = AminoAcidData(settings)

  # Run once, to force compilation.
  println("-- First run --")
  Random.seed!(20150326)
  @time kpax3mcmc(x, partition, settings)

  # Run a second time, with profiling.
  println("-- Second run --")
  Random.seed!(20150326)
  Profile.init(delay=0.01)
  Profile.clear()
  Profile.clear_malloc_data()
  @profile @time kpax3mcmc(x, partition, settings)

  # Write profile results
  r = Profile.retrieve()
  f = open("build/profile.bin", "w")
  serialize(f, r)
  close(f)

  nothing
end
