using Test, Statistics

pdir = joinpath(@__DIR__, "../examples/m12.6sl")
cd(pdir) do

  isdir("tmp") && rm("tmp", recursive=true);
  
  include(joinpath(pdir, "m12.6sl.jl"))

  @test 1.0 <  mean(m12_6sl[:alpha].value)< 1.2
  
  isdir("tmp") && rm("tmp", recursive=true);

end
