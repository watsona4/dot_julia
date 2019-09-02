#based on the optimizing radius tutorial
@testset "optimize radius" begin
    er = 4.5
    k0 = 2π
    kin = sqrt(er)*k0
    l0 = 2π/k0
    a = 0.2*l0
    ui = LineSource(-3a, 0)
    P = 5
    centers = square_grid(5, a)
    M = size(centers,1)
    # let's impose symmetry wrt x-axis
    centers_abs = centers[:,1] + 1im*abs.(centers[:,2])
    ids, centers_abs = uniqueind(centers_abs)
    J = maximum(ids) #number of optim vars
    φs = zeros(M)

    fmm_options = FMMoptions(true, acc = 6, dx = 2a)
    optim_options =  Optim.Options(x_tol = 1e-4, outer_x_tol = 1e-4,
                            iterations = 10, outer_iterations = 10,
                            store_trace = true, allow_f_increases = true)

    points = [3a 0.0]
    r_max = (0.4*a)*ones(J)
    r_min = (1e-3*a)*ones(J)
    rs0 = (0.25*a)*ones(J)
    @assert verify_min_distance([CircleParams(r_max[i]) for i = 1:J],
            centers, ids, points)

    res = optimize_radius(rs0, r_min, r_max, points, ids, P, ui, k0, kin,
            centers, fmm_options, optim_options, minimize = true)
    rs = res.minimizer
    @test res.x_converged

    optim_options2 =  Optim.Options(f_tol = 1e-7, outer_f_tol = 1e-7,
                            iterations = 10, outer_iterations = 10,
                            store_trace = true, show_trace = false,
                            allow_f_increases = true)
    res2 = optimize_radius(rs0, r_min, r_max, points, ids, P, ui, k0, kin,
            centers, fmm_options, optim_options2, minimize = false,
            method = "LBFGS")
    @test res2.f_converged

    sp1 = ScatteringProblem([CircleParams(rs0[i]) for i = 1:J], ids, centers, φs)
    sp2 = ScatteringProblem([CircleParams(rs[i]) for i = 1:J], ids, centers, φs)

    points_ = [3a 0.0; 0.0 0.0]
    u1_5 = calc_near_field(k0, kin, 5, sp1, points_, ui; opt = fmm_options,
            verbose = false)
    u1_6 = calc_near_field(k0, kin, 6, sp1, points_, ui; opt = fmm_options,
            verbose = false)
    u1_7 = calc_near_field(k0, kin, 7, sp1, points_, ui; opt = fmm_options,
            verbose = false)
    u2_5 = calc_near_field(k0, kin, 5, sp2, points_, ui; opt = fmm_options,
            verbose = false)
    u2_6 = calc_near_field(k0, kin, 6, sp2, points_, ui; opt = fmm_options,
            verbose = false)
    u2_7 = calc_near_field(k0, kin, 7, sp2, points_, ui; opt = fmm_options,
            verbose = false)

    @test (norm(u1_5-u1_6)/norm(u1_6) < 1e-6) && (norm(u1_5-u1_7)/norm(u1_7) < 1e-6)
    @test (norm(u2_5-u2_6)/norm(u2_6) < 1e-6) && (norm(u2_5-u2_7)/norm(u2_7) < 1e-6)
end
