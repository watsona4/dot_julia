"""
    optimize_φ(φs0, points, P, ui::Einc, k0, kin, shapes, centers, ids, fmmopts,
        optimopts::Optim.Options, minimize = true)

Optimize the rotation angles of a particle collection for minimization or
maximization (depending on `minimize`) of the field intensity at `points`.
`optimopts` and `method` define the optimization method, convergence criteria,
and other optimization parameters.
`adjoint` dictates whether the gradient is calculated using the adjoint method
(faster) or directly.
Returns an object of type `Optim.MultivariateOptimizationResults`.
"""
function optimize_φ(φs0, points, P, ui::Einc, k0, kin, shapes, centers, ids, fmmopts,
                    optimopts::Optim.Options, method; minimize = true, adjoint = true)

    #stuff that is done once
    verify_min_distance(shapes, centers, ids, points) || error("Particles are too close.")
    mFMM, scatteringMatrices, scatteringLU, buf =
        prepare_fmm_reusal_φs(k0, kin, P, shapes, centers, ids, fmmopts)
    Ns = size(centers,1)
    H = optimizationHmatrix(points, centers, Ns, P, k0)
    α = u2α(k0, ui, centers, P)
    uinc_ = uinc(k0, points, ui)
    # Allocate buffers
    shared_var = OptimBuffer(Ns,P,size(points,1))
    initial_φs = copy(φs0)
    last_φs = similar(initial_φs)
    last_φs == initial_φs && (last_φs[1] += 1) #should never happen but has

    fopt = φs -> ifelse(minimize,1,-1)*optimize_φ_f(φs, shared_var, last_φs, α,
                                        H, points, P, uinc_, Ns, k0, centers,
                                        scatteringMatrices, ids, mFMM, fmmopts,
                                        buf)
    if adjoint
        gopt! = (grad_stor, φs) -> optimize_φ_adj_g!(grad_stor, φs, shared_var,
                                    last_φs, α, H, points, P, uinc_, Ns, k0,
                                    centers, scatteringMatrices, scatteringLU,
                                    ids, mFMM, fmmopts, buf, minimize)
    else
        gopt! = (grad_stor, φs) -> optimize_φ_g!(grad_stor, φs, shared_var,
                                    last_φs, α, H, points, P, uinc_, Ns, k0,
                                    centers, scatteringMatrices, scatteringLU,
                                    ids, mFMM, fmmopts, buf, minimize)
    end
    df = OnceDifferentiable(fopt, gopt!, initial_φs)
    optimize(df, initial_φs, method, optimopts)
end

function optimize_φ_common!(φs, last_φs, shared_var, α, H, points, P, uinc_, Ns, k0, centers, scatteringMatrices, ids, mFMM, opt, buf)
    if φs != last_φs
        copyto!(last_φs, φs)
        #do whatever common calculations and save to shared_var
        #construct rhs
        for ic = 1:Ns
            rng = (ic-1)*(2*P+1) .+ (1:2*P+1)
            if φs[ic] == 0.0
                buf.rhs[rng] = scatteringMatrices[ids[ic]]*α[rng]
            else
                #rotate without matrix
                rotateMultipole!(view(buf.rhs,rng),view(α,rng),-φs[ic],P)
                buf.rhs[rng] = scatteringMatrices[ids[ic]]*buf.rhs[rng]
                rotateMultipole!(view(buf.rhs,rng),φs[ic],P)
            end
        end

        MVP = LinearMap{eltype(buf.rhs)}(
                (output_, x_) -> FMM_mainMVP_pre!(output_, x_,
                                    scatteringMatrices, φs, ids, P, mFMM,
                                    buf.pre_agg, buf.trans),
                Ns*(2*P+1), Ns*(2*P+1), ismutating = true)

        fill!(shared_var.β,0.0)
        shared_var.β,ch = gmres!(shared_var.β, MVP, buf.rhs,
                            restart = Ns*(2*P+1), tol = opt.tol, log = true,
							initially_zero = true) #no restart, preconditioning
        !ch.isconverged && error("FMM process did not converge")

        shared_var.f[:] = transpose(H)*shared_var.β
        shared_var.f .+= uinc_
    end
end

function optimize_φ_f(φs, shared_var, last_φs, α, H, points, P, uinc_, Ns, k0, centers,scatteringMatrices, ids, mFMM, opt, buf)
    optimize_φ_common!(φs, last_φs, shared_var, α, H, points, P, uinc_, Ns,
        k0, centers,scatteringMatrices, ids, mFMM, opt, buf)

    func = sum(abs2, shared_var.f)
end

function optimize_φ_g!(grad_stor, φs, shared_var, last_φs, α, H, points, P, uinc_, Ns, k0, centers, scatteringMatrices, scatteringLU, ids, mFMM, opt, buf, minimize)
    optimize_φ_common!(φs, last_φs, shared_var, α, H, points, P, uinc_, Ns,
        k0, centers,scatteringMatrices, ids, mFMM, opt, buf)

    MVP = LinearMap{eltype(buf.rhs)}(
            (output_, x_) -> FMM_mainMVP_pre!(output_, x_, scatteringMatrices,
                                            φs, ids, P, mFMM, buf.pre_agg,
                                            buf.trans),
            Ns*(2*P+1), Ns*(2*P+1), ismutating = true)
    #time for gradient
    shared_var.rhs_grad[:] = 0.0
    shared_var.∂β[:] = 0.0
    D = -1.0im*collect(-P:P)
    tempn = Array{Complex{Float64}}(undef, 2*P+1)
    for n = 1:Ns
        #compute n-th gradient
        rng = (n-1)*(2*P+1) .+ (1:2*P+1)
        rotateMultipole!(tempn, shared_var.β[rng], -φs[n], P)
        tempn[:] = scatteringLU[ids[n]]\tempn #LU decomp with pivoting
        tempn[:] .*= -D
        v = view(shared_var.rhs_grad, rng)
        mul!(v, scatteringMatrices[ids[n]], tempn)
        rotateMultipole!(v, φs[n], P)
        v[:] += D.*shared_var.β[rng]

        shared_var.∂β[:,n], ch = gmres!(view(shared_var.∂β,:,n), MVP,
                                    shared_var.rhs_grad, restart = Ns*(2*P+1),
                                    tol = 10*opt.tol, log = true,
									initially_zero = true)
        #@warn("using dbdn_tol = 10*opt.tol = $(10*opt.tol)")

        if ch.isconverged == false
            display("FMM process did not converge for partial derivative $n/$Ns. ")
            error("..")
        end
        #prepare for next one
        v[:] = 0.0im
    end

    grad_stor[:] = ifelse(minimize, 2, -2)*
                    real(transpose(shared_var.∂β)*(H*conj(shared_var.f)))
end


function optimize_φ_adj_g!(grad_stor, φs, shared_var, last_φs, α, H, points, P, uinc_, Ns, k0, centers, scatteringMatrices, scatteringLU, ids, mFMM, opt, buf, minimize)
    optimize_φ_common!(φs, last_φs, shared_var, α, H, points, P, uinc_, Ns,
        k0, centers,scatteringMatrices, ids, mFMM, opt, buf)

    MVP = LinearMap{eltype(buf.rhs)}(
            (output_, x_) -> FMM_mainMVP_transpose!(output_, x_,
                                scatteringMatrices, φs, ids, P, mFMM,
                                buf.pre_agg, buf.trans),
            Ns*(2*P+1), Ns*(2*P+1), ismutating = true)

    #build rhs of adjoint problem
    shared_var.rhs_grad[:] = -(H*conj(shared_var.f))
    #solve adjoint problem
    λadj, ch = gmres(MVP, shared_var.rhs_grad, restart = Ns*(2*P+1),
                    tol = opt.tol, log = true)
    # λadj, ch = gmres!(λadj, MVP, shared_var.rhs_grad, restart = Ns*(2*P+1),
    #                 tol = opt.tol, log = true, initially_zero = true)
    if ch.isconverged == false
        display("FMM process did not converge for adjoint system.")
        error("..")
    end

    #note: this assumes that there are exactly 2P+1 non zero elements in ∂X. If
    #not, v must be (2P+1)Ns × 1.
    D = -1.0im*collect(-P:P)
    v = Array{Complex{Float64}}(undef, 2P+1) #TODO: minimize dynamic alloc
    for n = 1:Ns
        #compute n-th element of gradient
        rng = (n-1)*(2*P+1) .+ (1:2*P+1)
        rotateMultipole!(v, view(shared_var.β,rng), -φs[n], P)
        v[:] = scatteringLU[ids[n]]\v #LU decomp with pivoting
        v[:] .*= -D
        v[:] = scatteringMatrices[ids[n]]*v
        rotateMultipole!(v, φs[n], P)
        v[:] += D.*shared_var.β[rng]

        grad_stor[n] = ifelse(minimize, -2, 2)*real(transpose(view(λadj,rng))*v)
        #prepare for next one - #TODO: check why this is here
        v[:] .= 0.0im
    end
end

function optimizationHmatrix(points, centers, Ns, P, k0)
    points_moved = Array{Float64}(undef, 2)
    H = Array{Complex{Float64}}(undef, Ns*(2*P+1), size(points,1))
    for ic = 1:Ns, i = 1:size(points,1)
        points_moved[1] = points[i,1] - centers[ic,1]
        points_moved[2] = points[i,2] - centers[ic,2]
        r_angle = atan(points_moved[2], points_moved[1])
        kr = k0*hypot(points_moved[1], points_moved[2])

        ind = (ic-1)*(2*P+1) + P + 1
        H[ind,i] = besselh(0, kr)
        for l = 1:P
            b = besselh(l, kr)
            H[ind + l,i] = b*exp(1.0im*l*r_angle)
            H[ind - l,i] = b*(-1)^l*exp(-1.0im*l*r_angle)
        end
    end
    H
end

function prepare_fmm_reusal_φs(k0, kin, P, shapes, centers, ids, fmmopt)
    #setup FMM reusal
    Ns = size(centers,1)
    groups, boxSize = divideSpace(centers, fmmopt)
    P2, Q = FMMtruncation(fmmopt.acc, boxSize, k0)
    mFMM = FMMbuildMatrices(k0, P, P2, Q, groups, centers, boxSize, tri = true)
    scatteringMatrices,innerExpansions = particleExpansion(k0, kin, shapes, P, ids)
    scatteringLU = [lu(scatteringMatrices[iid]) for iid = 1:length(shapes)]
    buf = FMMbuffer(Ns,P,Q,length(groups))
    return mFMM, scatteringMatrices, scatteringLU, buf
end
