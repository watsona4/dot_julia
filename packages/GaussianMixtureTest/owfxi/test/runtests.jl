using Distributions
using GaussianMixtureTest
using Test

mu_true = [-2.0858,-1.4879]
wi_true = [0.0828,0.9172]
sigmas_true = [0.6735,0.2931]

m = MixtureModel(map((u, v) -> Normal(u, v), mu_true, sigmas_true), wi_true)
x = rand(m, 1000);

wi, mu, sigmas, ml = gmm(x, 2)
mhat = MixtureModel(map((u, v) -> Normal(u, v), mu, sigmas), wi)
@test loglikelihood(mhat, x) >= loglikelihood(m, x)

asymptoticdistribution(x, wi_true, mu_true, sigmas_true);
T, p = kstest(x, 2)

@test T >= 0
# write your own tests here
