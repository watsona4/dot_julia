using Test, Statistics

pdir = joinpath(@__DIR__, "..", "examples", "mcmcchains")
cd(pdir) do

  isdir("tmp") && rm("tmp", recursive=true);
  
  include(joinpath(pdir, "mcmcchains.jl"))

  @test 18.0 <  mean(chn.value) < 22.0
  
  isdir("tmp") && rm("tmp", recursive=true);

end
