using StanBase

stan_prog = "
data { 
  int<lower=1> N; 
  int<lower=0,upper=1> y[N];
  real empty[0];
} 
parameters {
  real<lower=0,upper=1> theta;
} 
model {
  theta ~ beta(1,1);
  y ~ bernoulli(theta);
}
";

stanmodel = HelpModel( "help", stan_prog;
  method = StanBase.Help(help=:sample))

stan_help(stanmodel;n_chains=1)

run(`cat $(stanmodel.output_base*"_chain_1.log")`)
