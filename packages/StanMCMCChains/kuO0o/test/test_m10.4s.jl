using Test, Statistics

pdir = joinpath(@__DIR__, "..", "examples", "m10.4s")
cd(pdir) do

  isdir("tmp") && rm("tmp", recursive=true);
  
  include(joinpath(pdir, "m10.4s.jl"))

  @test 0.8 < mean(m10_4s[:bp].value) < 0.9
  
  isdir("tmp") && rm("tmp", recursive=true);

end