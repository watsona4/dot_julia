using CmdStan, StanMCMCChain, Test, Statistics

ProjDir = joinpath(dirname(@__FILE__), "..", "examples", "Bernoulli")
cd(ProjDir) do

  isdir("tmp") && rm("tmp", recursive=true);
    
  include("../examples/Bernoulli/bernoulli.jl")

  @test 0.1 <  mean(chains.value[:, 8, :] ) < 0.6
    
  isdir("tmp") && rm("tmp", recursive=true);

end # cd
