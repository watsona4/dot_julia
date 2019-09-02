#based on the optimizing angle tutorial
@testset "optimize angle" begin
    λ0 = 1 #doesn't matter since everything is normalized to λ0
    k0 = 2π/λ0
    kin = 0.5k0
    pw = PlaneWave(0.0)
    M = 20

    sfun(N) = rounded_star(0.35λ0, 0.1λ0, 4, N)
    # N, errN = minimumN(k0, kin, sfun; tol=1e-6, N_start = 200, N_min = 100,
                # N_max = 400)
    shapes = [sfun(202)]
    P = 12#P, errP = minimumP(k0, kin, shapes[1]; P_max = 30, tol = 1e-7)

    centers =  rect_grid(2, div(M,2), λ0, λ0) #2xM/2 grid with distance λ0
    ids = ones(Int, M)
    φs0 = zeros(M)
    sp = ScatteringProblem(shapes, ids, centers, φs0)

    points = [-0.05 0.0; 0.05 0.0; 0.0 0.05; 0.0 -0.05]
    @assert verify_min_distance(sp, points)

    fmm_options = FMMoptions(true, acc = 6, dx = 2λ0)

    optim_options = Optim.Options(f_tol = 1e-6, iterations = 50,
                        store_trace = true, show_trace = false)
    optim_method = Optim.BFGS(;linesearch = LineSearches.BackTracking())
    res_min = optimize_φ(φs0, points, P, pw, k0, kin, shapes, centers, ids, fmm_options,
            optim_options, optim_method; minimize = true)
    @test res_min.f_converged
    res_max = optimize_φ(φs0, points, P, pw, k0, kin, shapes, centers, ids, fmm_options,
            optim_options, optim_method; minimize = false)
    @test res_max.f_converged
    sp_min = ScatteringProblem(shapes, ids, centers, res_min.minimizer)
    sp_max = ScatteringProblem(shapes, ids, centers, res_max.minimizer)

    u_bef = calc_near_field(k0, kin, P, sp, points, pw;
            opt = fmm_options, verbose = false)
    u_min = calc_near_field(k0, kin, P, sp_min, points, pw; opt = fmm_options,
            verbose = false)
    u_max = calc_near_field(k0, kin, P, sp_max, points, pw; opt = fmm_options,
            verbose = false)

    fobj0 = sum(abs2.(u_bef))
    fobj_min = sum(abs2.(u_min))
    fobj_max = sum(abs2.(u_max))
    @test fobj_max > fobj0 && fobj_min < fobj0
    @test isapprox(res_min.trace[1].value, fobj0)
    @test isapprox(res_min.minimum, fobj_min)
    @test isapprox(-res_max.minimum, fobj_max)

    border = find_border(sp, points)
end
