#for now just the main functions, no wrapper
function optimize_pwr_φ_common!(φs, last_φs, opb, power_buffer, ids, scatteringMatrices, P, Ns, fmmbuf, fmmopts, mFMM)
    if φs != last_φs
        copyto!(last_φs, φs)
        #do whatever common calculations and save to shared_var
        for i in eachindex(opb)
            for ic = 1:Ns
                rng = (ic-1)*(2*P+1) .+ (1:2*P+1)
                if φs[ic] == 0.0
                    fmmbuf.rhs[rng] = scatteringMatrices[i][ids[ic]]*opb[i].α[rng]
                else
                    #rotate without matrix
                    rotateMultipole!(view(fmmbuf.rhs,rng), view(opb[i].α,rng), -φs[ic], P)
                    fmmbuf.rhs[rng] = scatteringMatrices[i][ids[ic]]*fmmbuf.rhs[rng]
                    rotateMultipole!(view(fmmbuf.rhs,rng), φs[ic], P)
                end
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

function optimize_pwr_φ_f(φs, last_φs, opb, power_buffer, ids, scatteringMatrices, P, Ns, fmmbuf, fmmopts, mFMM, fobj_pwr)
    optimize_pwr_φ_common!(φs, last_φs, opb, power_buffer, ids, scatteringMatrices, P, Ns, fmmbuf, fmmopts, mFMM)

    fobj_pwr(power_buffer)
end

function optimize_pwr_φ_g!(grad_stor, φs, last_φs, opb, power_buffer, ids, scatteringMatrices, scatteringLU, P, Ns, fmmbuf, fmmopts, mFMM, gobj_pwr!)
    optimize_pwr_φ_common!(φs, last_φs, opb, power_buffer, ids, scatteringMatrices, P, Ns, fmmbuf, fmmopts, mFMM)

    fill!(grad_stor, 0) #gradient is the sum of all adjoint gradients
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
                            restart = Ns*(2*P+1), tol = fmmopts.tol,
                            log=true, initially_zero = true) #no restart
        !ch.isconverged && error("""FMM process did not converge for adjoint,
            normalized residual:
            $(norm(MVP*opb[i].λadj - opb[i].rhs_grad)/norm(opb[i].rhs_grad))""")
        D = -1.0im*collect(-P:P)
        v = Array{Complex{Float64}}(undef, 2*P+1) #TODO: minimize dynamic alloc
        v2 = Array{Complex{Float64}}(undef, 2*P+1)
        for n = 1:Ns
            rng = (n-1)*(2*P+1) .+ (1:2*P+1)
            rotateMultipole!(v, view(opb[i].β,rng), -φs[n], P)
            ldiv!(scatteringLU[i][ids[n]], v)
            v2[:] = scatteringMatrices[i][ids[n]]*v
            v2 .*= D
            v .*= D
            v[:] = scatteringMatrices[i][ids[n]]*v
            v2 .-= v
            rotateMultipole!(v2, φs[n], P)
            grad_stor[n] += (-2)*real(transpose(opb[i].λadj[rng])*v2)
        end
    end
end
