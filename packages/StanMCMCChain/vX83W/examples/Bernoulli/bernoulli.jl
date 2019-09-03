######### CmdStan program example  ###########

using CmdStan, StanMCMCChain, MCMCChain, Test, JLD, Statistics

ProjDir = dirname(@__FILE__)
cd(ProjDir) do

  bernoullimodel = "
  data { 
    int<lower=1> N; 
    int<lower=0,upper=1> y[N];
  } 
  parameters {
    real<lower=0,upper=1> theta;
  } 
  model {
    theta ~ beta(1,1);
    y ~ bernoulli(theta);
  }
  "

  observeddata = [
    Dict("N" => 10, "y" => [0, 1, 0, 1, 0, 0, 0, 0, 0, 1]),
    Dict("N" => 10, "y" => [0, 1, 0, 0, 0, 0, 1, 0, 0, 1]),
    Dict("N" => 10, "y" => [0, 0, 0, 0, 0, 0, 1, 0, 1, 1]),
    Dict("N" => 10, "y" => [0, 0, 0, 1, 0, 0, 0, 1, 0, 1])
  ]

  global stanmodel, rc, chains, cnames, d
  
  stanmodel = Stanmodel(num_samples=1200, thin=1, name="bernoulli", 
    model=bernoullimodel, output_format=:mcmcchain);

 @time rc, chains, cnames = stan(stanmodel, observeddata, ProjDir, diagnostics=false,
    CmdStanDir=CMDSTAN_HOME);
    
  describe(chains)
  println()
    
  @time save("tmp/chains.jld", 
    "range", chains.range, 
    "a3d", chains.value,
    "names", chains.names, 
    "chains", chains.chains)
  println()
  
  @time d = load(joinpath(ProjDir, "tmp", "chains.jld"))
  println()

  chn2 = MCMCChain.Chains(d["a3d"], names=d["names"])
  
  describe(chn2) 
  
  @test 0.1 <  mean(chn2.value[:, 8, :] ) < 0.6
  
end # cd
