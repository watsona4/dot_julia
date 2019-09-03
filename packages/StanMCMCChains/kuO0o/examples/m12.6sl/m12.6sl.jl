
using CSV, DataFrames, StanMCMCChains, MCMCChains

ProjDir = @__DIR__
cd(ProjDir)

d = CSV.read("Kline.csv", delim=';');
size(d) # Should be 10x5

# New col log_pop, set log() for population data
d[:log_pop] = map((x) -> log(x), d[:population]);
d[:society] = 1:10;

first(d, 5)

m12_6sl_model = "
  data {
    int N;
    int T[N];
    int N_societies;
    int society[N];
    int P[N];
  }
  parameters {
    real alpha;
    vector[N_societies] a_society;
    real bp;
    real<lower=0> sigma_society;
  }
  model {
    vector[N] mu;
    target += normal_lpdf(alpha | 0, 10);
    target += normal_lpdf(bp | 0, 1);
    target += cauchy_lpdf(sigma_society | 0, 1);
    target += normal_lpdf(a_society | 0, sigma_society);
    for(i in 1:N) mu[i] = alpha + a_society[society[i]] + bp * log(P[i]);
    target += poisson_log_lpmf(T | mu);
  }
  generated quantities {
    vector[N] log_lik;
    {
    vector[N] mu;
    for(i in 1:N) {
      mu[i] = alpha + a_society[society[i]] + bp * log(P[i]);
      log_lik[i] = poisson_log_lpmf(T[i] | mu[i]);
    }
    }
  }
";

# Define the Stanmodel and set the output format to :mcmcchain.

stanmodel = Stanmodel(name="m12.6.2sl_model",  num_samples=4000, 
model=m12_6sl_model);

# Input data for cmdstan

m12_6sl_data = Dict("N" => size(d, 1), "T" => d[:total_tools], 
"N_societies" => 10, "society" => d[:society], "P" => d[:population]);
        
# Sample using cmdstan

rc, a3d, cnames = stan(stanmodel, m12_6sl_data, ProjDir, 
diagnostics=false, summary=false, CmdStanDir=CMDSTAN_HOME);

# Describe the draws

cnames1 = cnames
cnames1[9:18] =  ["a_society[$i]" for i in 1:10]        
cnames1[21:30] =  ["log_lik[$i]" for i in 1:10]        

pi = filter(p -> length(p) > 2 && p[end-1:end] == "__", cnames1)
p = filter(p -> !(p in  pi), cnames1)
p1 = ["alpha", "bp", "sigma_society"]
p2 = filter(p -> !(p in p1), p)

m12_6sl = MCMCChains.Chains(a3d,
  cnames1,
  Dict(
    :parameters => p1,
    :pooled => cnames1[9:18],
    :log_lik => cnames1[21:30],
    :internals => pi
  )
)

write(joinpath(ProjDir, "sections_m12_6sl.jls"), m12_6sl)
open(joinpath(ProjDir, "sections_m12_6sl.txt"), "w") do io
  describe(io, m12_6sl, section=:pooled);
end

describe(m12_6sl)

describe(m12_6sl, section=:pooled)

describe(m12_6sl, section=:log_lik)

