"""
    asymptoticdistribution(x, wi, mu, sigmas);

Simulate the asymptotic distribution of test statistic for `kstest`.
`nrep` is the number of random values to generate.
`debuginfo` is whether to show the debug information.
When number of components of null distribution is greater than 1, the test statistic has no closed form asymptotic distribution. When the null distribution is just normal, the asymptotic distribution is just `Chisq(2)`.

"""
function asymptoticdistribution(x::RealVector{Float64}, wi::Vector{Float64}, mu::Vector{Float64}, sigmas::Vector{Float64}; nrep::Int=10000, debuginfo::Bool=false)

    n = length(x)
    C = length(wi)
    m = MixtureModel(map((u, v) -> Normal(u, v), mu, sigmas), wi)
    llC = zeros(n, C)
    S_π = zeros(n, C-1)
    S_μσ = zeros(n, 2*C)
    S_λ = zeros(n, 2*C)
    ll = logpdf.(m, x)
    for i in 1:n, kcom in 1:C
        llC[i, kcom] = logpdf(m.components[kcom], x[i])
    end

    for kcom in 1:(C-1)
        S_π[:, kcom] = exp.(llC[:, kcom] .- ll) .- exp.(llC[:, C] .- ll) #(llC[:, kcom] .- llC[:, C]) ./ ll
    end
    for i in 1:n
        for kcom in 1:C
            llC[i, kcom] = exp(log(wi[kcom]) + llC[i, kcom] - ll[i])
            S_μσ[i, 2*kcom-1] = H1(x[i], mu[kcom], sigmas[kcom]) * llC[i, kcom]
            S_μσ[i, 2*kcom] = H2(x[i], mu[kcom], sigmas[kcom]) * llC[i, kcom]
            S_λ[i, 2*kcom-1] = H3(x[i], mu[kcom], sigmas[kcom]) * llC[i, kcom]
            S_λ[i, 2*kcom] = H4(x[i], mu[kcom], sigmas[kcom]) * llC[i, kcom]
        end
    end
    S_η = hcat(S_π, S_μσ)
    debuginfo && println(round(llC[1:5,:], 6))
    debuginfo && println(sum(S_η, 1))
    debuginfo && println(sum(S_λ, 1))
    I_η = S_η'*S_η./n
    I_λη = S_λ'*S_η./n
    I_λ = S_λ'*S_λ./n
    I_all = vcat(hcat(I_η, I_λη'), hcat(I_λη, I_λ))
    if 1/cond(I_all) < eps(Float64)
        D, V = eigen((I_all .+ transpose(I_all))./ 2)
        debuginfo && println(D)
        tol2 = maximum(abs.(D)) * 1e-14
        D[D.<tol2] .= tol2
        I_all = V*Matrix(Diagonal(D))*V'
    end
    debuginfo && println(round(cor(S_η), 6))
    debuginfo && println(round(cor(S_λ), 6))
    I_λ_η = I_all[(3*C):(5*C-1), (3*C):(5*C-1)] - I_all[(3*C):(5*C-1), 1:(3*C-1)] * inv(I_all[1:(3*C-1), 1:(3*C-1)]) * I_all[1:(3*C-1),(3*C):(5*C-1)]
    debuginfo && println(round(I_λ_η, 6))
    #I_λ_η=(I_λ_η .+ I_λ_η')./2
    D, V = eigen((I_λ_η .+ transpose(I_λ_η)) ./ 2)
    D[D.<0.] .= 0.
    debuginfo && println(D)
    I_λ_η2 = V * Matrix(Diagonal(sqrt.(D))) * V'
    u = randn(nrep, 2*C) * I_λ_η2
    EM = zeros(nrep, C)
    T = zeros(nrep)
    for kcom in 1:C
        EM[:, kcom] = sum(u[:, (2*kcom-1):(2*kcom)] * inv(I_λ_η[(2*kcom-1):(2*kcom), (2*kcom-1):(2*kcom)]) .* u[:, (2*kcom-1):(2*kcom)], dims=2)
    end
    for i in 1:nrep
        T[i] = maximum(EM[i, :])
    end
    debuginfo && println(EM[1:10,:])
    T
end

"""
    gmmrepeat(x, C)

Repeat the `gmm` for `ntrials` randomly generated starting values and pick the one with largest penalized likelihood.

 - `wi_init`, `mu_lb`, `mu_ub`, `sigmas_lb`, `sigmas_ub`: specify how to generate the random starting values
 - `taufixed`, `whichtosplit`, `tau`: whether keep the ratio between `wi[whichtosplit]` and `wi[whichtosplit]+wi[whichtosplit+1]` fixed at a constant `tau`.
 - `sn` and `an`: the penalty
 - `debuginfo` and `tol`: whether print the debug information and the convergence critera
 - `pl`: wheter the penalty on `sigmas` be included in the log likelihood in the final two EM steps. Note that the starting value with largest penalized log likelihood is picked, but the penalty term should not be included in the likelihood ratio
 - `ptau`: whether to add the penalty on `tau` be included in likelihood. Better to be `true` since the more `tau` values we try the larger the test statistic

"""
function gmmrepeat(x::RealVector, C::Int,
    wi_init::Vector{Float64},
    mu_init::Vector{Float64},
    sigmas_init::Vector{Float64};
    ntrials::Int=25,
    taufixed::Bool=false, whichtosplit::Int=1, tau::Real=0.5,
   sn::Vector{Float64}=std(x).*ones(C), an::Real=1/length(x), debuginfo::Bool=false, tol::Real=.001, pl::Bool=false, ptau::Bool=false)

    n = length(x)
    tau = min(tau, 1-tau)
    mu_lb = minimum(x) .* ones(C)
    mu_ub = maximum(x) .* ones(C)
    if taufixed && C>2
        for kcom in 1:(C-1)
            tmp = (mu_init[kcom+1]*(wi_init[kcom+1])^.25 +mu_init[kcom]*(wi_init[kcom])^.25) / ((wi_init[kcom+1])^.25+(wi_init[kcom])^.25)
            mu_lb[kcom+1] = tmp
            mu_ub[kcom] = tmp
        end
        mu_lb[whichtosplit+1]=mu_lb[whichtosplit]
        mu_ub[whichtosplit]=mu_ub[whichtosplit+1]
    end
    debuginfo && println(mu_lb, mu_ub)
    sigmas_lb = 0.25 .* sigmas_init
    sigmas_ub = 2 .* sigmas_init

    if taufixed
        tmp = wi_init[whichtosplit] + wi_init[whichtosplit+1]
        wi_init[whichtosplit] = tmp*tau
        wi_init[whichtosplit+1] = tmp*(1-tau)
        mu_init[whichtosplit] -= 1e-3
    end

    wi = repeat(wi_init, 1, 4*ntrials)
    mu = repeat(mu_init, 1, 4*ntrials)
    sigmas = repeat(sigmas_init, 1, 4*ntrials)
    ml = -Inf .* ones(4*ntrials)
    for i in 1:4*ntrials
        #set the first initial value as mu_init, sigmas_init
        if i >= 2
            mu[:, i] = rand(C) .* (mu_ub .- mu_lb) .+ mu_lb
            sigmas[:, i] = rand(C) .* (sigmas_ub .- sigmas_lb) .+ sigmas_lb
        end

        wi[:, i], mu[:, i], sigmas[:, i], ml[i] =
             gmm(x, C, wi[:, i], mu[:, i], sigmas[:, i],
             taufixed=taufixed, whichtosplit=whichtosplit, tau=tau,
             mu_lb=mu_lb, mu_ub=mu_ub,
             maxiteration=100, sn=sn, an=an,
             tol=tol, pl=true, ptau=false)
    end

    mlperm = sortperm(ml)
    for j in 1:ntrials
        i = mlperm[4*ntrials+1 - j] # start from largest ml
        wi[:, i], mu[:, i], sigmas[:, i], ml[i] =
            gmm(x, C, wi[:, i], mu[:, i], sigmas[:, i],
            taufixed=taufixed, whichtosplit=whichtosplit, tau=tau,
            mu_lb=mu_lb, mu_ub=mu_ub,
            sn=sn, an=an,
            tol=tol, pl=true, ptau=false)
    end

    mlmax, imax = findmax(ml[mlperm[(3*ntrials+1):4*ntrials]])
    imax = mlperm[3*ntrials+imax]

    re=gmm(x, C, wi[:, imax], mu[:, imax], sigmas[:, imax],
         maxiteration=2, an=an, sn=sn, tol=0., pl=pl, ptau=ptau, whichtosplit=whichtosplit)
    debuginfo && println("Trial:", re)
    return(re)
end

"""
    kstest(x, C0)

Do the EM test under null Hypothesis of `C0` components.
If rejected, then it suggest the true number of components is greater than `C0`.
Optional arguments for `kstest`

 - `vtau`: the finite set of `tau` value, default to try 0.5 only
 - `ntrials`: the number of initial values to try, default to be 25
 - `debuginfo`: whether show the debug information

"""
function kstest(x::RealVector{Float64}, C0::Int; vtau::Vector{Float64}=[.5;],
    ntrials::Int=25, debuginfo::Bool=false, tol::Real=0.001,ptau::Bool=true)

    C1 = C0+1
    n = length(x)

    wi_init, mu_init, sigmas_init, ml_C0 = gmm(x, C0)
    wi_init, mu_init, sigmas_init, ml_C0 = gmmrepeat(x, C0, wi_init, mu_init, sigmas_init, pl=false, ptau=false, an=1/n)
    debuginfo && println(wi_init, mu_init, sigmas_init, ml_C0)
    if C0 > 1
        trand=GaussianMixtureTest.asymptoticdistribution(x, wi_init, mu_init, sigmas_init)
    end

    if debuginfo
        println("ml_C0=", ml_C0)
    end
    minx = minimum(x)
    maxx = maximum(x)
    or = sortperm(mu_init)
    wi0 = wi_init[or]
    mu0 = mu_init[or]
    sigmas0 = sigmas_init[or]
    an = decidepenalty(wi0, mu0, sigmas0, n)
    lr = 0.0
    lrv = zeros(length(vtau), C0)
    for whichtosplit in 1:C0, i in 1:length(vtau)
        ind = [1:whichtosplit; whichtosplit:C0;]

        wi_C1 = wi0[ind]
        wi_C1[whichtosplit] = wi_C1[whichtosplit]*vtau[i]
        wi_C1[whichtosplit+1] = wi_C1[whichtosplit+1]*(1-vtau[i])

        lrv[i, whichtosplit] = gmmrepeat(x, C1,
         wi_C1, mu0[ind], sigmas0[ind],
         ntrials=ntrials,
         taufixed=true, whichtosplit=whichtosplit, tau=vtau[i],
         sn=sigmas0[ind], an=an,
         debuginfo=debuginfo, tol=tol, pl=false, ptau=ptau)[4]
       if debuginfo
           println(whichtosplit, " ", vtau[i], "->",
           lrv[i, whichtosplit])
       end
   end
   lr = maximum(lrv)
   if debuginfo
       println("lr=", lr)
   end
   Tvalue = 2*(lr - ml_C0)
   if C0 == 1
       pvalue = 1 - cdf(Chisq(2), Tvalue)
   else
       pvalue = mean(trand .> Tvalue)
   end
   return(Tvalue, pvalue)
end
