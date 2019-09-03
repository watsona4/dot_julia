# Load Julia packages (libraries) needed  for the snippets in chapter 0

using CSV, DataFrames, StanMCMCChains, MCMCChains, Test

# CmdStan uses a tmp directory to store the output of cmdstan

ProjDir = @__DIR__
cd(ProjDir)

# ### snippet 10.4

d = CSV.read("chimpanzees.csv", delim=';');
df = convert(DataFrame, d);

first(df, 5)

# Define the Stan language model

m_10_04 = "
data{
    int N;
    int N_actors;
    int pulled_left[N];
    int prosoc_left[N];
    int condition[N];
    int actor[N];
}
parameters{
    vector[N_actors] a;
    real bp;
    real bpC;
}
model{
    vector[N] p;
    bpC ~ normal( 0 , 10 );
    bp ~ normal( 0 , 10 );
    a ~ normal( 0 , 10 );
    for ( i in 1:504 ) {
        p[i] = a[actor[i]] + (bp + bpC * condition[i]) * prosoc_left[i];
        p[i] = inv_logit(p[i]);
    }
    pulled_left ~ binomial( 1 , p );
}
";

# Define the Stanmodel and set the output format to :mcmcchain.

stanmodel = Stanmodel(name="m_10_04", model=m_10_04);

# Input data for cmdstan

m_10_04_data = Dict("N" => size(df, 1), "N_actors" => length(unique(df[:actor])), 
"actor" => df[:actor], "pulled_left" => df[:pulled_left],
"prosoc_left" => df[:prosoc_left], "condition" => df[:condition]);

# Sample using cmdstan

rc, a3d, cnames = stan(stanmodel, m_10_04_data, ProjDir, diagnostics=false,
  summary=true, CmdStanDir=CMDSTAN_HOME);

# Result rethinking

m10_4s = "
Iterations = 1:1000
Thinning interval = 1
Chains = 1,2,3,4
Samples per chain = 1000

Empirical Posterior Estimates:
        Mean        SD       Naive SE       MCSE      ESS
a.1 -0.74582030 0.27434131 0.0043377170 0.0046716919 1000
a.2 10.84504358 5.15213698 0.0814624384 0.1318154262 1000
a.3 -1.05763045 0.28946248 0.0045768036 0.0050400879 1000
a.4 -1.05554020 0.28720358 0.0045410873 0.0053160144 1000
a.5 -0.74383955 0.27076943 0.0042812406 0.0047354636 1000
a.6  0.22481354 0.27204394 0.0043013924 0.0050574284 1000
a.7  1.81239042 0.39557281 0.0062545552 0.0076427689 1000
 bp  0.84439020 0.26762425 0.0042315109 0.0055762860 1000
bpC -0.13763738 0.30026364 0.0047475851 0.0046440490 1000
";

cnames1 = cnames
cnames1[8:14] =  ["a[$i]" for i in 1:7]        

pi = filter(p -> length(p) > 2 && p[end-1:end] == "__", cnames1)
p = filter(p -> !(p in  pi), cnames1)
p1 = ["bp", "bpC"]
p2 = filter(p -> !(p in p1), p)

m10_4s = MCMCChains.Chains(a3d,
  cnames1,
  Dict(
    :parameters => p1,
    :pooled => p2,
    :internals => pi
  )
)

write(joinpath(ProjDir, "sections_m10.4s.jls"), m10_4s)
open(joinpath(ProjDir, "sections_m10.4s.txt"), "w") do io
  describe(io, m10_4s, section=:pooled);
end

describe(m10_4s)
