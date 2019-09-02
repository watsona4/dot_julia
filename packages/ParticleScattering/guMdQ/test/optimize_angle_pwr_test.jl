@testset "optimize angle power" begin
    λ0 = 1 #doesn't matter since everything is normalized to λ0
    k0 = 2π/λ0
    kin = 3k0
    ui = PlaneWave(0.0)
    M = 10

    sfun(N) = rounded_star(0.35λ0, 0.1λ0, 4, N)
    # N, errN = minimumN(k0, kin, sfun; tol=1e-6, N_start = 200, N_min = 100,
                # N_max = 400)
    shapes = [sfun(202)]
    P = 12#P, errP = minimumP(k0, kin, shapes[1]; P_max = 30, tol = 1e-7)

    centers = rect_grid(2, div(M,2), λ0, λ0) #2xM/2 grid with distance λ0
    ids = ones(Int, M)
    φs0 = zeros(M)
    sp = ScatteringProblem(shapes, ids, centers, φs0)

    points = [2λ0*ones(15) range(minimum(centers[:,2]), stop=maximum(centers[:,2]), length=15)]
    nhat = [ones(15) zeros(15)]
    len = norm(points[1,:] - points[end,:])
    @assert verify_min_distance(sp, points)

    fmm_options = FMMoptions(true, acc = 6, dx = 2λ0)
    groups,boxSize = divideSpace(sp.centers, fmm_options)
    P2,Q = FMMtruncation(fmm_options.acc, boxSize, k0)
    optim_options = Optim.Options(f_tol = 1e-5, iterations = 50,
                        store_trace = true, show_trace = false)

    # Allocate buffers
    opb = [OptimProblemBuffer(k0, kin, sp.centers, ui, P)]
    power_buffer = [optMatrixPwr(points, sp.centers, M, P, k0, ui, 1, nhat, len)]
    mFMM = [FMMbuildMatrices(k0, P, P2, Q, groups, sp.centers, boxSize, tri = true)]
    buf = FMMbuffer(M, P, Q, length(groups))
    scatteringMatrices,innerExpansions = particleExpansion(k0, kin, shapes, P, ids)
    scatteringMatrices = [scatteringMatrices]
    scatteringLU = [[lu(scatteringMatrices[1][iid]) for iid = 1:length(shapes)]]

    function fobj_test(sv::Array{PowerBuffer})
        res = -sv[1].pow
    end

    function gobj_test!(sv::Array{PowerBuffer}, opb::Array{OptimProblemBuffer})
        #calculate -(∂f/∂β)ᵀ for adjoint method
        opb[1].rhs_grad[:] = sv[1].∂pow
    end

    #initial, last must be different before first iteration
    last_φs = similar(φs0); last_φs[1] = NaN; @assert(last_φs != φs0)
    df = Optim.OnceDifferentiable(
        φs -> optimize_pwr_φ_f(φs, last_φs, opb, power_buffer, ids, scatteringMatrices, P, M, buf, fmm_options, mFMM, fobj_test),
        (grad_stor, φs) -> optimize_pwr_φ_g!(grad_stor, φs, last_φs, opb, power_buffer, ids, scatteringMatrices, scatteringLU, P, M, buf, fmm_options, mFMM, gobj_test!),
        φs0)

    res = Optim.optimize(df, φs0, Optim.LBFGS(), optim_options)

    power_after = calc_power(k0, kin, P, ScatteringProblem(shapes, ids, centers,
                    res.minimizer), points, nhat, ui)*len
    @test res.f_converged
    @test power_after ≈ 0.00094388385
end
