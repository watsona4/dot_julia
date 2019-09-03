using FileIO, JLD, MCMCChain

function jldsave(filepath::AbstractString, chains::MCMCChain.Chains)
  println("Entering save")
  open(filepath, "w") do s
      # Don't forget to write the magic bytes!
      write(s, magic(format"JLD"))
      # Do the rest of the stuff needed to save in JLD format
      JLD.save(s, 
        "range", chains.range, 
        "values", chains.value,
        "names", chains.names, 
       "chains", chains.chains)
   end
end

function jldload(filepath::AbstractString)
  println("Entering load")
  open(filepath, "w") do s
    skipmagic(s)  # skip over the magic bytes
    d = JLD.load(filepath)
  end
 MCMCChain.Chains(d["values"], names=d["names"], chains=d["chains"],
    start=first(d["range"]), thin=step(d["range"]))
end

#=
ProjDir = rel_path("..", "testexamples", "mcmc", "mamba")
cd(ProjDir) do
  
  save("sim.jld", 
    "range", sim.range, 
    "values", sim.value,
    "names", sim.names, 
    "chains", sim.chains)
    
end

d = load(joinpath(ProjDir, "sim.jld"))
=#