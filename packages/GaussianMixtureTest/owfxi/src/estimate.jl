
function pn(sigma1::Float64,  sigmahat::Float64; an::Float64=0.25)
    -((sigmahat / sigma1)^2 + 2*log(sigma1 / sigmahat) -1) * an
end
pn(sigma1::Vector{Float64},  sigmahat::Float64; an::Float64 = .25)=Float64[pn(sigma1[i], sigmahat, an=an) for i in 1:length(sigma1)]
pn(sigma1::Vector{Float64},  sigmahat::Vector{Float64}; an::Float64 = .25)=Float64[pn(sigma1[i], sigmahat[i], an=an) for i in 1:length(sigma1)]

function decidepenalty(wi0::Vector, mu0::Vector, sigmas0::Vector, nobs::Int)
    C = length(wi0)
    or = sortperm(mu0)
    wi = wi0[or]
    mu = mu0[or]
    sigmas = sigmas0[or]
    if C==1
        return 0.25
    elseif C == 2
        omega = omega12(wi, mu, sigmas)
        omega = min(max(omega, 1e-16), 1 - 1e-16)
        x = exp(-1.642 -0.434*log(omega/(1-omega)) -101.80/nobs)
        return 1.8*x/(1+x)
    elseif C == 3
        omega = omega123(wi, mu, sigmas)
        omega = min.(max.(omega, 1e-16), 1 - 1e-16)
        t_omega = (omega[1]*omega[2])/(1-omega[1])/(1-omega[2])
        x =  exp(-1.678 -0.232*log(t_omega) -175.50/nobs)
        return 1.5*x/(1+x)
    else
        return 1.0
    end
end
function omegaji(alpi,mui,sigi,alpj,muj,sigj)
# Computes omega_{j|i} defined in (2.1) of Maitra and Melnykov
    if sigi==sigj
        delta = abs(mui-muj)/sigi
        out = pdf(Normal(), -delta/2 + log(alpj/alpi)/delta)
    else
        ncp = (mui-muj)*sigi/(sigi^2-sigj^2)
        value=sigj^2*(mui-muj)^2/(sigj^2-sigi^2)^2-sigj^2/(sigi^2-sigj^2)*log(alpi^2*sigj^2/alpj^2/sigi^2 )
        sqrtvalue = sqrt(max(value,0.0))

        ind = float(sigi<sigj)
        out = ind + (-1)^ind*(pdf(Normal(), sqrtvalue-ncp)-pdf(Normal(), -sqrtvalue-ncp))
    end
    return(out)
end	# end function omega.ji

function omega12(wi, mu, sigmas)
# Computes omega_{12} for testing H_0:m=2 against H_1:m=3
    alp1 = wi[1]
    alp2 = wi[2]

    mu1 = mu[1]
    mu2 = mu[2]

    sig1 = sigmas[1]
    sig2 = sigmas[2]

    part1 = omegaji(alp1,mu1,sig1,alp2,mu2,sig2)
    part2 = omegaji(alp2,mu2,sig2,alp1,mu1,sig1)

    return((part1+part2)/2)
end	# end function omega.12

function omega123(wi, mu, sigmas)

    alp1 = wi[1]
    alp2 = wi[2]
    alp3 = wi[3]

    mu1 = mu[1]
    mu2 = mu[2]
    mu3 = mu[3]

    sig1 = sigmas[1]
    sig2 = sigmas[2]
    sig3 = sigmas[3]

    part1 = omegaji(alp1,mu1,sig1,alp2,mu2,sig2)
    part2 = omegaji(alp2,mu2,sig2,alp1,mu1,sig1)
    w12 = (part1+part2)/2

    part3 = omegaji(alp2,mu2,sig2,alp3,mu3,sig3)
    part4 = omegaji(alp3,mu3,sig3,alp2,mu2,sig2)
    w23 = (part3+part4)/2

    return([w12,w23])

end	# end function omega.123

function stopRule(pa::Vector, pa_old::Vector; tol=.005)
    maximum(abs.(pa .- pa_old)./(abs.(pa).+.001)) < tol
end

"""
   gmm(x, ncomponent)

Estimate parameters of `ncomponent` gaussian mixture on the data `x`.
Optional arguments of `gmm`:

 - `ncomponent`: the number of components
 - `wi_init` `mu_init` and `sigmas_init`: the initial values
 - `maxiteration`: the number of iterations
 - `tol`: the tolerance of convergence criteria
 - `an` and `sn`: the penalty weight and variance term
 - `taufixed`: for `kstest`, whether fix the `tau` value
 - `whichtosplit` and `tau`: for `kstest`, which component to split and the `split` proportion
 - `mu_lb` and `mu_ub` for `kstest`, the lower and upper limits of components means
 - `pl`: wheter the penalty on `sigmas` be included in the log likelihood in the final two EM steps. Note that the starting value with largest penalized log likelihood is picked, but the penalty term should not be included in the likelihood ratio
 - `ptau`: whether to add the penalty on `tau` be included in likelihood. Better to be `true` since the more `tau` values we try the larger the test statistic


"""
function gmm(x::RealVector{Float64}, ncomponent::Int,
    wi_init::Vector{Float64}=ones(ncomponent)/ncomponent,
     mu_init::Vector{Float64}=quantile(x, range(0, stop=1, length=ncomponent+2)[2:end-1]),
     sigmas_init::Vector{Float64}=ones(ncomponent).*std(x);
      whichtosplit::Int64=1, tau::Float64=.5,
       mu_lb::Vector{Float64}=-Inf.*ones(length(wi_init)),
        mu_ub::Vector{Float64}=Inf.*ones(length(wi_init)),
        an::Float64=1/length(x), sn::Vector{Float64}=ones(ncomponent).*std(x),
         maxiteration::Int64=10000, tol::Real=.001, taufixed::Bool=false, pl::Bool=false, ptau::Bool=false)

    if ncomponent == 1
        mu = [mean(x)]
        sigmas = [std(x)]
        ml = loglikelihood(Normal(mean(x), std(x)), x)
        if pl
            ml += sum(pn(sigmas, sn, an=an))
        end
        return([1.0], mu, sigmas, ml)
    end
    n = length(x)
    tau = min(tau, 1-tau)
    wi = copy(wi_init)
    mu = copy(mu_init)
    sigmas = copy(sigmas_init)
    wi_old = copy(wi)
    mu_old = copy(mu)
    sigmas_old=copy(sigmas)

    wi_divide_sigmas = zeros(length(wi))
    inv_2sigmas_sq = ones(length(sigmas))
    pwi = ones(n, ncomponent)
    xtmp = copy(x)

    for iter_em in 1:maxiteration

        @inbounds for j in 1:length(wi)
            wi_divide_sigmas[j] = wi[j]/sigmas[j]
            inv_2sigmas_sq[j] = 0.5 / sigmas[j]^2
        end

        for i in 1:n
            tmp = -Inf
            @inbounds for j in 1:ncomponent
                pwi[i, j] = -(mu[j] - x[i])^2 * inv_2sigmas_sq[j]
                if tmp < pwi[i,j]
                    tmp = pwi[i,j]
                end
            end
            #@inbounds tmp = maximum(pwi[i, :])
            for j in 1:ncomponent
                @inbounds pwi[i, j] -= tmp
            end
        end
        Yeppp.exp!(pwi, pwi)

        @inbounds for i in 1:n
            tmp = 0.0
            for j in 1:ncomponent
                pwi[i, j] *= wi_divide_sigmas[j]
                tmp += pwi[i, j]
            end
            for j in 1:ncomponent
                pwi[i, j] /= tmp
            end
        end

        copyto!(wi_old, wi)
        copyto!(mu_old, mu)
        copyto!(sigmas_old, sigmas)

        for j in 1:ncomponent
            colsum = sum(pwi[:, j])
            if colsum == 0.
                wi[j] = 1/n
                sigmas[j] *=2
                @warn("Empty component occur at iteration $(iter_em). Auto increase its variance by a factor 2. wi=$(wi), mu=$(mu), sigmas=$(sigmas)")
                continue
            end
            wi[j] = colsum / n
            mu[j] = wsum(pwi[:,j], x) / colsum

            add!(xtmp, x, -mu[j], n)
            sqr!(xtmp, xtmp, n)
            sigmas[j] = sqrt((wsum(pwi[:,j], xtmp) + 2 * an * sn[j]^2) / (colsum + 2*an))
        end
        tmp = sum(wi)
        for j in 1:ncomponent
            wi[j] /= tmp
        end
        if any(isnan.(wi))|| any(isnan.(mu)) || any(isnan.(sigmas))
            println( wi, mu, sigmas)
            error("NaN occur!")
        end
        if taufixed
            wi_tmp = wi[whichtosplit]+wi[whichtosplit+1]
            wi[whichtosplit] = wi_tmp*tau
            wi[whichtosplit+1] = wi_tmp*(1-tau)
            mu = min.(max.(mu, mu_lb), mu_ub)
        end

        if stopRule(vcat(wi, mu, sigmas), vcat(wi_old, mu_old, sigmas_old), tol=tol)
            break
        end
    end
    m = MixtureModel(map((u, v) -> Normal(u, v), mu, sigmas), wi)

    ml = loglikelihood(m, x)# + sum(pn(sigmas, sn, an=an)) #+ log(1 - abs(1 - 2*tau))
    if pl
        ml += sum(pn(sigmas, sn, an=an))
    end
    if ptau
        tau2 = wi[whichtosplit] / (wi[whichtosplit]+wi[whichtosplit+1])
        ml += log(1 - abs(1 - 2*tau2))
    end
    return (wi, mu, sigmas, ml)
end

function confidenceinterval(x::RealVector{Float64}, wi::Vector{Float64}, mu::Vector{Float64}, sigmas::Vector{Float64}; confidencelevel::Real=0.9, debuginfo::Bool=false)

    n = length(x)
    C = length(wi)
    m = MixtureModel(map((u, v) -> Normal(u, v), mu, sigmas), wi)
    llC = zeros(n, C)
    S_π = zeros(n, C-1)
    S_μσ = zeros(n, 2*C)
    S_λ = zeros(n, 2*C)
    ll = logpdf(m, x)
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
    if 1/cond(I_η) < eps(Float64)
        warn("Information Matrix is singular!")
        D, V = eig(I_η)
        debuginfo && println(D)
        tol2 = maximum(abs(D)) * 1e-14
        D[D.<tol2] = tol2
        I_η = V*diagm(D)*V'
    end
    shat = sqrt.(diag(inv(I_η))./n)
    println("Parameter Standard Deviation: ", shat)
    tmp = quantile(Normal(), 1-(1-confidencelevel) / 2 )
    zip([wi[1:(C-1)]; mu; sigmas;] .- tmp.*shat, [wi[1:(C-1)]; mu; sigmas;] .+ tmp.*shat) |> collect
end
