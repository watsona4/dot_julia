using StanVariational
using Test

bernoulli_model = "
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
";

bernoulli_data = Dict("N" => 10, "y" => [0, 1, 0, 1, 0, 0, 0, 0, 0, 1])

stanmodel = VariationalModel("bernoulli", bernoulli_model)

(sample_file, log_file) = stan_variational(stanmodel; data=bernoulli_data)

if sample_file !== Nothing

  @testset "Bernoulli optimize example" begin
    # Read sample summary (in ChainDataFrame format)
    sdf = read_summary(stanmodel)

    @test sdf[:theta, :mean][1] ≈ 0.32 atol=0.1
  end

end