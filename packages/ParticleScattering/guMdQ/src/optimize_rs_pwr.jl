#for now just the main functions, no wrapper
#remove all unnecessary allocations
mutable struct PowerBuffer #one for each *power calculation* (can be > 1 for each frequency/incident wave)
    iₚ::Integer #which problem (β) is this??
    Ez::Vector{Complex{Float64}}
    Hx::Vector{Complex{Float64}}
    Hy::Vector{Complex{Float64}}
    Ez_inc::Vector{Complex{Float64}}
    Hx_inc::Vector{Complex{Float64}}
    Hy_inc::Vector{Complex{Float64}}
    pow::Float64 #power
    HEz::Vector{Vector{Complex{Float64}}}
    HHx::Vector{Vector{Complex{Float64}}}
    HHy::Vector{Vector{Complex{Float64}}}
    nhat::Array{Float64,2}
    S::Array{Complex{Float64},2}
    ∂pow::Vector{Complex{Float64}} # ∂power/∂βᵀ
    l::Float64 #arc length
    PowerBuffer(Ns::Integer, P::Integer, nhat, iₚ) =
            new(iₚ,
                Array{Complex{Float64}}(undef, size(nhat, 1)),
                Array{Complex{Float64}}(undef, size(nhat, 1)),
                Array{Complex{Float64}}(undef, size(nhat, 1)),
                Array{Complex{Float64}}(undef, size(nhat, 1)),
                Array{Complex{Float64}}(undef, size(nhat, 1)),
                Array{Complex{Float64}}(undef, size(nhat, 1)),
                0.0,
                [Array{Complex{Float64}}(undef, Ns*(2P+1)) for i=1:size(nhat, 1)],
                [Array{Complex{Float64}}(undef, Ns*(2P+1)) for i=1:size(nhat, 1)],
                [Array{Complex{Float64}}(undef, Ns*(2P+1)) for i=1:size(nhat, 1)],
                nhat,
                Array{Complex{Float64},2}(undef, size(nhat)),
                Array{Complex{Float64}}(undef, Ns*(2P+1)),
                0.0)
end

#TODO: take k0,ui from opb
function optMatrixPwr(points, centers, Ns, P, k0, ui, iₚ, nhat, l)
    sv = PowerBuffer(Ns, P, nhat, iₚ)
    cf = 1/(1im*k0*eta0)
    pt = Array{Float64}(undef, 2)
    for ip = 1:size(points,1)
        for ic = 1:Ns
            pt[1] = points[ip,1] - centers[ic,1]
            pt[2] = points[ip,2] - centers[ic,2]
            θ = atan(pt[2], pt[1])
            R = hypot(pt[1], pt[2])

            ind = (ic-1)*(2*P+1) .+ P + 1
            Hₚ₋₂ = besselh(-1, 1, k0*R)
            Hₚ₋₁ = besselh(0, 1, k0*R)

            sv.HEz[ip][ind] = Hₚ₋₁
            ∂H∂R = k0*Hₚ₋₂
            sv.HHx[ip][ind] = cf*∂H∂R*pt[2]/R
            sv.HHy[ip][ind] = -cf*∂H∂R*pt[1]/R
            for p = 1:P
                Hₚ = (2*(p-1)/(k0*R))*Hₚ₋₁ - Hₚ₋₂
                ∂H∂R = k0*(Hₚ₋₁ - (p/k0/R)*Hₚ)
                sv.HEz[ip][ind - p] = (-1)^p*Hₚ*exp(-1im*p*θ)
                sv.HHy[ip][ind - p] = -cf*exp(-1im*p*θ)*(-1)^p*(∂H∂R*pt[1] - Hₚ*1im*p*(-pt[2])/R)/R
                sv.HHx[ip][ind - p] = cf*exp(-1im*p*θ)*(-1)^p*(∂H∂R*pt[2] - Hₚ*1im*p*(pt[1])/R)/R

                sv.HEz[ip][ind + p] = Hₚ*exp(1im*p*θ)
                sv.HHy[ip][ind + p] = -cf*exp(1im*p*θ)*(∂H∂R*pt[1] + Hₚ*1im*p*(-pt[2])/R)/R
                sv.HHx[ip][ind + p] = cf*exp(1im*p*θ)*(∂H∂R*pt[2] + Hₚ*1im*p*(pt[1])/R)/R
                Hₚ₋₂ = Hₚ₋₁; Hₚ₋₁ = Hₚ
            end
        end
    end
    sv.l = l
    sv.Ez_inc = uinc(k0, points, ui)
    sv.Hx_inc = hxinc(k0, points, ui)
    sv.Hy_inc = hyinc(k0, points, ui)
    sv
end

mutable struct OptimProblemBuffer#one for each problem, e.g. 3 if same incident wave but 3 different frequencies, or 2 if same frequency but different incident wave
    k0::Float64
    kin::Float64
    α::Vector{Complex{Float64}}
    ui::Einc
    β::Vector{Complex{Float64}}
    rhs_grad::Vector{Complex{Float64}}
    λadj::Vector{Complex{Float64}}
end

function OptimProblemBuffer(k0::Float64, kin::Float64, centers::Array{Float64,2}, ui::Einc, P::Integer)
    Ns = size(centers, 1)
    α = ParticleScattering.u2α(k0, ui, centers, P)
    OptimProblemBuffer(k0, kin, α, ui,
        Array{Complex{Float64}}(undef, Ns*(2*P+1)),
        Array{Complex{Float64}}(undef, Ns*(2*P+1)),
        Array{Complex{Float64}}(undef, Ns*(2*P+1)))
end

function optimize_pwr_rs_common!(rs, last_rs, opb, power_buffer, ids, scatteringMatrices, dS_S, P, Ns, fmmbuf, fmmopts, φs, mFMM)
    if rs != last_rs
        copyto!(last_rs, rs)
        #do whatever common calculations and save to shared_var
        for i in eachindex(opb)
            #TODO: if multiple problems have same k0, these calcs are duplicated
            for id in unique(ids)
                ParticleScattering.updateCircleScatteringDerivative!(scatteringMatrices[i][id], dS_S[i][id], opb[i].k0, opb[i].kin, rs[id], P)
            end
            for ic = 1:Ns
                rng = (ic-1)*(2*P+1) .+ (1:2*P+1)
                fmmbuf.rhs[rng] = scatteringMatrices[i][ids[ic]]*opb[i].α[rng]
            end

            MVP = LinearMap{eltype(fmmbuf.rhs)}(
                        (output_, x_) -> ParticleScattering.FMM_mainMVP_pre!(output_, x_,
                                            scatteringMatrices[i], φs, ids, P, mFMM[i],
                                            fmmbuf.pre_agg, fmmbuf.trans),
                        Ns*(2*P+1), Ns*(2*P+1), ismutating = true)

            opb[i].β[:] .= 0
            opb[i].β,ch = gmres!(opb[i].β, MVP, fmmbuf.rhs,
                                    restart = Ns*(2*P+1), tol = fmmopts.tol,
                                    log = true, initially_zero = true) #no restart
            !ch.isconverged && error("""FMM process did not converge, normalized
                residual: $(norm(MVP*opb[i].β - fmmbuf.rhs)/norm(fmmbuf.rhs))""")
        end
        #calculate power for each power calculation arc
        calc_multi_pwr!(power_buffer, opb)
    end
end

function optimize_pwr_rs_f(rs, last_rs, opb, power_buffer, ids, scatteringMatrices, dS_S, P, Ns, fmmbuf, fmmopts, φs, mFMM, fobj_pwr)
    optimize_pwr_rs_common!(rs, last_rs, opb, power_buffer, ids, scatteringMatrices, dS_S, P, Ns, fmmbuf, fmmopts, φs, mFMM)

    fobj_pwr(power_buffer)
end

function optimize_pwr_rs_g!(grad_stor, rs, last_rs, opb, power_buffer, ids, scatteringMatrices, dS_S, P, Ns, fmmbuf, fmmopts, φs, mFMM, gobj_pwr!)
    optimize_pwr_rs_common!(rs, last_rs, opb, power_buffer, ids, scatteringMatrices, dS_S, P, Ns, fmmbuf, fmmopts, φs, mFMM)

    fill!(grad_stor, 0) #gradient is the sum of both adjoint gradients
    #compute all ∂P/∂βᵀ
    dPdβ_pwr!.(power_buffer)
    #build rhs of all adjoint problems (⁠-∂f/∂βᵀ)
    gobj_pwr!(power_buffer, opb)

    #for each problem, solve adjoint problem and add to total gradient
    for i in eachindex(opb)
        MVP = LinearMap{eltype(fmmbuf.rhs)}(
                (output_, x_) -> ParticleScattering.FMM_mainMVP_transpose!(output_, x_,
                                        scatteringMatrices[i], φs, ids, P, mFMM[i],
                                        fmmbuf.pre_agg, fmmbuf.trans),
                Ns*(2*P+1), Ns*(2*P+1), ismutating = true)

        #solve adjoint problem
        opb[i].λadj[:] .= 0
        opb[i].λadj, ch = gmres!(opb[i].λadj, MVP, opb[i].rhs_grad,
                            restart = Ns*(2*P+1), tol = fmmopts.tol, log = true,
                            initially_zero = true) #no restart
        for n = 1:length(rs)
            #compute n-th gradient - here we must pay the price for symmetry
            #as more than one β is affected. Overwrites rhs_grad (ok because
            #there is seperate one for each i). TODO:
            #rhs_grad is still usually sparse - utilize this to reduce complexity
            #here O(N^2) -> O(N)
            for ic = 1:Ns
                rng = (ic-1)*(2*P+1) .+ (1:2*P+1)
                if ids[ic] == n
                    opb[i].rhs_grad[rng] = dS_S[i][n]*opb[i].β[rng]
                else
                    opb[i].rhs_grad[rng] .= 0.0
                end
            end
            grad_stor[n] += -2*real(transpose(opb[i].λadj)*opb[i].rhs_grad)
        end
    end
end

function calc_multi_pwr!(power_buffer, opb)
    for sv in power_buffer
        len = length(sv.HEz)
        Sn = Array{Complex{Float64}}(undef, len) # S⋅n
        βi = opb[sv.iₚ].β
        for ip = 1:len
            sv.Ez[ip] = transpose(sv.HEz[ip])*βi + sv.Ez_inc[ip]
            sv.Hx[ip] = transpose(sv.HHx[ip])*βi + sv.Hx_inc[ip]
            sv.Hy[ip] = transpose(sv.HHy[ip])*βi + sv.Hy_inc[ip]
            Sn[ip] = -0.5*real(sv.Ez[ip]*conj(sv.Hy[ip]))*sv.nhat[ip,1]
            Sn[ip] += 0.5*real(sv.Ez[ip]*conj(sv.Hx[ip]))*sv.nhat[ip,2]
        end
        sv.pow = (sum(Sn) - 0.5*Sn[1] - 0.5*Sn[end])*sv.l/(len-1) #trapezoidal rule, correct up to arc length for simple integrals
    end
end

function dPdβ_pwr!(sv::PowerBuffer)
    len = length(sv.Ez) #num of points
    fill!(sv.∂pow, 0.0)
    #this is a sum of real and imaginary parts, hence the additional 1/2 factor
    for ip = 1:len
        cf = ifelse(ip == 1 || ip == len, 0.5, 1.0)*sv.l/(len-1) #trapezoidal rule constant
        sv.∂pow .+= (-0.25*cf*sv.nhat[ip,1])*(conj(sv.Hy[ip])*sv.HEz[ip] +
                                    conj(sv.Ez[ip])*sv.HHy[ip])
        sv.∂pow .+= (0.25*cf*sv.nhat[ip,2])*(conj(sv.Hx[ip])*sv.HEz[ip] +
                                    conj(sv.Ez[ip])*sv.HHx[ip])
    end
end
