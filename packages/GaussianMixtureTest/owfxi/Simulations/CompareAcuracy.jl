# Compare the selection accuracy of KS test and BIC for different sample size
@everywhere using GaussianMixtureTest: gmm, kstest
@everywhere using Distributions:Normal, MixtureModel
@everywhere using Random:seed!


@everywhere function compareBIC(Ctrue::Int, n::Int, b::Int)

    C_max = max(5, (2*Ctrue - 1))
    mu_all = log(1/0.779 - 1)
    if Ctrue == 2
        mu_true = [mu_all - 1.0, mu_all + 0.8]
        wi_true =  [.6, .4]
        sigmas_true = [1.2, .8]
    elseif Ctrue == 3
        mu_true = [mu_all - 2.0, mu_all + 1.0, mu_all + 3.5]
        wi_true = [.3, .4, .3]
        sigmas_true = [1.2, .8, .9]
    end
    m = MixtureModel(map((u, v) -> Normal(u, v), mu_true, sigmas_true), wi_true)

    C_max = max(5, (2*Ctrue - 1))
    bic = fill(Inf, C_max)
    pvalues = fill(1.0, C_max)

    seed!(b)
    x = rand(m, n);
    for C in 1:C_max
        wi, mu, sigmas, ml = gmm(x, C)
        T, pvalues[C] = kstest(x, C)
        bic[C] = -2 * ml + (3 * C - 1) * log(n)
    end
    vcat(bic, pvalues)
end
