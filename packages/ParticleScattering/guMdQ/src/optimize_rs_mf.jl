const cₚ = 10.0 #penalty term for unwanted frequency

function optimize_rs_mf(rs0, r_min, r_max, points, point_flags, ids, P, ui, k0,
                        kin, centers, fmmopts, optimopts::Optim.Options;
                        method = BFGS(linesearch = LineSearches.BackTracking()))

    Ns = size(centers,1)
    φs = zeros(Ns)
    Nk = length(k0); @assert Nk == length(kin)
    J = length(rs0)
    @assert maximum(ids) <= J
    if length(r_min) == 1
        r_min = r_min*ones(Float64,J)
    else
        @assert J == length(r_min)
    end
    if length(r_max) == 1
        r_max = r_max*ones(Float64,J)
    else
        @assert J == length(r_max)
    end
    verify_min_distance(CircleParams.(r_max), centers, ids,
        points) || error("Particles are too close or r_max are too large.")

    groups,boxSize = divideSpace(centers, fmmopts)
    P2,Q = FMMtruncation(fmmopts.acc, boxSize, maximum(k0))
    mFMM = [FMMbuildMatrices(k0[ik], P, P2, Q, groups, centers, boxSize) for ik = 1:Nk]
    scatteringMatrices = [[sparse(one(Complex{Float64})I, 2*P+1, 2*P+1) for i = 1:J] for ik = 1:Nk]
    dS_S = [[sparse(one(Complex{Float64})I, 2*P+1, 2*P+1) for i = 1:J] for ik = 1:Nk]

    #calculate nd expand incident field
    α = [u2α(k0[ik], ui, centers, P) for ik = 1:Nk]
    uinc_ = [uinc(k0[ik], points, ui) for ik = 1:Nk]
    H = [optimizationHmatrix(points, centers, Ns, P, k0[ik]) for ik = 1:Nk]

    # Allocate buffers
    buf = FMMbuffer(Ns,P,Q,length(groups))
    shared_var = [OptimBuffer(Ns, P, size(points,1), J) for ik = 1:Nk]
    initial_rs = copy(rs0)
    last_rs = similar(initial_rs); last_rs[1] = NaN; @assert last_rs != initial_rs #initial_rs, last_rs must be different before first iteration
    df = OnceDifferentiable(
        rs -> optimize_rs_mf_f(rs, last_rs, shared_var, φs, α, H, points, point_flags,
                            P, uinc_, Ns, k0, kin, centers, scatteringMatrices, dS_S,
                            ids, mFMM, fmmopts, buf),
        (grad_stor, rs) -> optimize_rs_mf_g!(grad_stor, rs, last_rs, shared_var, φs,
                            α, H, points, point_flags, P, uinc_, Ns, k0, kin, centers,
                            scatteringMatrices, dS_S, ids, mFMM, fmmopts, buf),
        initial_rs)

    optimize(df, r_min, r_max, initial_rs, Fminbox(method), optimopts)
end

function optimize_rs_mf_common!(rs, last_rs, shared_var, φs, α,
            H, points, P, uinc_, Ns, k0, kin, centers, scatteringMatrices,
            dS_S, ids, mFMM, fmmopts, buf)
    if rs != last_rs
        copyto!(last_rs, rs)
        #do whatever common calculations and save to shared_var
        #construct rhs
        for ik in eachindex(k0)
            for id in unique(ids)
                updateCircleScatteringDerivative!(scatteringMatrices[ik][id],
                    dS_S[ik][id], k0[ik], kin[ik], rs[id], P)
            end
            for ic = 1:Ns
                rng = (ic-1)*(2*P+1) .+ (1:2*P+1)
                buf.rhs[rng] = scatteringMatrices[ik][ids[ic]]*α[ik][rng]
            end

            MVP = LinearMap{eltype(buf.rhs)}(
                        (output_, x_) -> FMM_mainMVP_pre!(output_, x_,
                                            scatteringMatrices[ik], φs, ids, P,
                                            mFMM[ik], buf.pre_agg, buf.trans),
                        Ns*(2*P+1), Ns*(2*P+1), ismutating = true)

            shared_var[ik].β[:] = 0
            shared_var[ik].β,ch = gmres!(shared_var[ik].β, MVP, buf.rhs,
                                    restart = Ns*(2*P+1), tol = fmmopts.tol,
                                    log = true, initially_zero = true)
            !ch.isconverged && error("""FMM process did not converge, normalized
                residual: $(norm(MVP*shared_var[ik].β - buf.rhs)/norm(buf.rhs))""")

            shared_var[ik].f[:] = transpose(H[ik])*shared_var[ik].β
            shared_var[ik].f[:] .+= uinc_[ik]
        end
    end
end

function optimize_rs_mf_f(rs, last_rs, shared_var, φs, α, H, points, point_flags,
                        P, uinc_, Ns, k0, kin, centers, scatteringMatrices, dS_S,
                        ids, mFMM, fmmopts, buf)
    optimize_rs_mf_common!(rs, last_rs, shared_var, φs, α, H, points, P, uinc_,
        Ns, k0, kin, centers, scatteringMatrices, dS_S, ids, mFMM, fmmopts, buf)

    fobj_rs_mf(shared_var, point_flags)
end

function optimize_rs_mf_g!(grad_stor, rs, last_rs, shared_var, φs, α, H, points,
            point_flags, P, uinc_, Ns, k0, kin, centers, scatteringMatrices, dS_S,
            ids, mFMM, opt, buf)
    optimize_rs_mf_common!(rs, last_rs, shared_var, φs, α, H, points, P, uinc_,
        Ns, k0, kin, centers, scatteringMatrices, dS_S, ids, mFMM, opt, buf)

    fill!(grad_stor, 0)
    for ik in eachindex(k0)
        MVP = LinearMap{eltype(buf.rhs)}(
                    (output_, x_) -> FMM_mainMVP_transpose!(output_, x_,
                                        scatteringMatrices[ik], φs, ids, P,
                                        mFMM[ik], buf.pre_agg, buf.trans),
                    Ns*(2*P+1), Ns*(2*P+1), ismutating = true)

        #build rhs of adjoint problem
        gobj_rs_mf!(shared_var, ik, H[ik], point_flags)
        #solve adjoint problem
        λadj, ch = gmres(MVP, shared_var[ik].rhs_grad, restart = Ns*(2*P+1),
                    tol = opt.tol, log = true)
        # λadj, ch = gmres!(λadj, MVP, shared_var.rhs_grad, restart = Ns*(2*P+1),
        #                 tol = opt.tol, log = true, initially_zero = true)

        for n = 1:length(rs)
            #compute n-th gradient - here we must pay the price for symmetry
            #as more than one beta is affected. Overwrites rhs_grad.
            for ic = 1:Ns
                rng = (ic-1)*(2*P+1) .+ (1:2*P+1)
                if ids[ic] == n
                    shared_var[ik].rhs_grad[rng] = dS_S[ik][n]*shared_var[ik].β[rng]
                else
                    shared_var[ik].rhs_grad[rng] = 0.0
                end
            end
            grad_stor[n] += -2*real(transpose(λadj)*shared_var[ik].rhs_grad)
        end
    end
end

function fobj_rs_mf(sv, point_flags)
    #emphasize field maximization
    fobj = 0.0
    for i in eachindex(point_flags)
        ik = point_flags[i]
        #add and subtract for easy sum
        sumu = sum(abs2, sv[jk].f[i] for jk in eachindex(sv)) - abs2(sv[ik].f[i])
        fobj += (1 + cₚ*sumu)/abs2(sv[ik].f[i])
    end
    fobj
end

function gobj_rs_mf!(sv, ik, H, point_flags)
    #calculate -(∂f/∂β)ᵀ for adjoint method
    fill!(sv[ik].rhs_grad, 0)
    for i in eachindex(point_flags)
        ik′ = point_flags[i]
        if ik == ik′
            sumu = sum(abs2, sv[jk].f[i] for jk in eachindex(sv))
            num = 1 + cₚ*(sumu - abs2(sv[ik].f[i]))
            denom = abs2(sv[ik].f[i])*sv[ik].f[i]
        else
            num = (-cₚ)*conj(sv[ik].f[i])
            denom = abs2(sv[ik′].f[i])
        end
        sv[ik].rhs_grad .+= view(H,:,i)*(num/denom)
    end
end
