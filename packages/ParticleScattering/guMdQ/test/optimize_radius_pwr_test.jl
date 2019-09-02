#two-sided diode-type test.
@testset "optimize radius power" begin
    λ0 = 1 #doesn't matter since everything is normalized to λ0
    k0 = 2π/λ0
    kin = 4k0
    ui = [PlaneWave(); PlaneWave(π)]
    a = λ0/2
    P = 6

    centers = rect_grid(4, 8, a, a) #symmetric 4x8 grid with distance a
    M = size(centers, 1)
    ids = ones(Int, M)
    φs = zeros(M)
    centers_abs = centers[:,1] + 1im*abs.(centers[:,2])
    ids, centers_abs = ParticleScattering.uniqueind(centers_abs)
    Nrs = maximum(ids) #if some are the same, Nrs is the number of different r
    initial_rs = 0.25*a*ones(Nrs)
    r_max = 0.45*a*ones(Nrs)
    r_min = 1e-4*a*ones(Nrs)
    shapes = CircleParams.(initial_rs)
    sp = ScatteringProblem(shapes, ids, centers, φs)
    Npoints = 15
    points1 = [2λ0*ones(Npoints) range(-λ0, stop=λ0, length=Npoints)]
    points2 = [-2λ0*ones(Npoints) range(-λ0, stop=λ0, length=Npoints)]
    nhat1 = [ones(Npoints) zeros(Npoints)]
    nhat2 = [-ones(Npoints) zeros(Npoints)]
    len = norm(points1[1,:] - points1[end,:]) #same for 2
    @assert verify_min_distance(sp, [points1;points2])

    fmm_options = FMMoptions(true, acc = 6, dx = λ0)
    groups,boxSize = divideSpace(sp.centers, fmm_options)
    P2,Q = FMMtruncation(fmm_options.acc, boxSize, k0)
    optim_options = Optim.Options(f_tol = 1e-5, iterations = 10, outer_iterations = 5,
                        store_trace = false, show_trace = false)
    # Allocate buffers
    opb = [OptimProblemBuffer(k0, kin, sp.centers, ui[1], P),
            OptimProblemBuffer(k0, kin, sp.centers, ui[2], P)]
    power_buffer = [optMatrixPwr(points1, sp.centers, M, P, k0, ui[1], 1, nhat1, len),
                    optMatrixPwr(points2, sp.centers, M, P, k0, ui[2], 2, nhat2, len)]
    mFMM = [FMMbuildMatrices(k0, P, P2, Q, groups, sp.centers, boxSize, tri = true) for i=1:2]
    buf = FMMbuffer(M, P, Q, length(groups))
    scatteringMatrices = [[sparse(one(Complex{Float64})I, 2P+1, 2P+1) for i = 1:Nrs] for i = 1:2]
    dS_S = [[sparse(one(Complex{Float64})I, 2P+1, 2P+1) for i = 1:Nrs] for i = 1:2]

    function fobj_testr(sv::Array{PowerBuffer})
        if sv[1].pow < 0 || sv[2].pow < 0
            return abs(sv[2].pow/sv[1].pow)*1e9 #instead of Inf
        end
        barr = -(log(sv[1].pow) + log(sv[2].pow)) #so they're > 0
        res = sv[2].pow/sv[1].pow
        res*(1 + barr)
    end

    function gobj_testr!(sv::Array{PowerBuffer}, opb::Array{OptimProblemBuffer})
        #calculate -(∂f/∂β)ᵀ for adjoint method
        if sv[1].pow < 0 || sv[2].pow < 0
            opb[1].rhs_grad[:] .= 0
            opb[2].rhs_grad[:] .= 0
            return
        end
        barr = -(log(sv[1].pow) + log(sv[2].pow))
        res = sv[2].pow/sv[1].pow
        opb[1].rhs_grad[:] = sv[1].∂pow*((1 + barr)*sv[2].pow/sv[1].pow^2)
        opb[2].rhs_grad[:] = sv[2].∂pow*(-(1 + barr)/sv[1].pow)
        opb[1].rhs_grad .+= sv[1].∂pow*(res/sv[1].pow)
        opb[2].rhs_grad .+= sv[2].∂pow*(res/sv[2].pow)
    end

    #initial, last must be different before first iteration
    last_rs = similar(initial_rs); @assert last_rs != initial_rs #initial_rs, last_rs must be different before first iteration
    df = Optim.OnceDifferentiable(
        rs -> optimize_pwr_rs_f(rs, last_rs, opb, power_buffer, ids, scatteringMatrices, dS_S, P, M, buf, fmm_options, φs, mFMM, fobj_testr),
        (grad_stor, rs) -> optimize_pwr_rs_g!(grad_stor, rs, last_rs, opb, power_buffer, ids, scatteringMatrices, dS_S, P, M, buf, fmm_options, φs, mFMM, gobj_testr!),
        initial_rs)

    res = Optim.optimize(df, r_min, r_max, initial_rs, Optim.Fminbox(Optim.LBFGS()), optim_options)
    sp_after = ScatteringProblem(CircleParams.(res.minimizer), ids, centers, φs)
    power_after_right = calc_power(k0, kin, P, sp_after, points1, nhat1, ui[1])*len
    power_after_left = calc_power(k0, kin, P, sp_after, points2, nhat2, ui[2])*len
    @test power_after_right > 0
    @test power_after_left > 0
    @test power_after_right/power_after_left > 1
end
