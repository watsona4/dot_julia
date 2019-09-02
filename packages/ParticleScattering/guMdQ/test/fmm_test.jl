@testset "FMM" begin
    λ0 = 1
    k0 = 2π/λ0
    kin = 3k0
    θ_i = π/4 #incident wave e^{i k_0 (1/sqrt{2},1/sqrt{2}) \cdot \mathbf{r}}
    N_squircle = 200
    N_star = 210
    P = 10

    M = 10
    shapes = [rounded_star(0.1λ0, 0.03λ0, 5, N_star);
                squircle(0.15λ0, N_squircle)]
    ids = rand(1:2, M^2)
    φs = 2π*rand(M^2) #random rotation angles
    dist = 2*maximum(shapes[i].R for i=1:2)
    try
        centers = randpoints(M^2, dist, 5λ0, 5λ0, [0.0 0.0; 0.01+dist 0.01],
                    failures = 1_000)
        sp = ScatteringProblem(shapes, ids, centers, φs)
        @test verify_min_distance(sp, [0.0 0.0; 0.01+dist 0.01])
    catch
        @warn("Could not find random points (1)")
    end
    try
        centers = randpoints(M^2, dist, 5λ0, 5λ0, failures = 1_000)
        sp = ScatteringProblem(shapes, ids, centers, φs)
        @test verify_min_distance(sp)
    catch
        @warn("Could not find random points (2)")
    end

    centers =  rect_grid(M, M, 0.8λ0, λ0)
    sp = ScatteringProblem(shapes, ids, centers, φs)
    fmm_options = FMMoptions(true, acc = 6, nx = div(M,2))

    groups,boxSize = divideSpace(centers, fmm_options; drawGroups = false)
    P2,Q = FMMtruncation(6, boxSize, k0)
    mFMM1 = FMMbuildMatrices(k0, P, P2, Q, groups, centers, boxSize; tri = false)
    mFMM2 = FMMbuildMatrices(k0, P, P2, Q, groups, centers, boxSize; tri = true)
    @test norm(mFMM1.Znear - mFMM2.Znear, Inf) == 0

    points = [range(-λ0*M, stop=λ0*M, length=200) zeros(200)]
    u1 = calc_near_field(k0, kin, P, sp, points, PlaneWave(θ_i); opt = fmm_options,
            verbose = false)
    u2 = calc_near_field(k0, kin, P, sp, points, PlaneWave(θ_i); opt = fmm_options,
            verbose = true, method = "density")
    @test norm(u1 - u2)/norm(u1) < 1e-6

    u3 = calc_near_field(k0, kin, P, sp, points, LineSource(-0.8λ0,-λ0);
            opt = fmm_options, verbose = false)
    u4 = calc_near_field(k0, kin, P, sp, points, LineSource(-0.8λ0,-λ0);
            opt = fmm_options, verbose = true, method = "recurrence")
    @test norm(u3 - u4)/norm(u3) < 1e-6

    #test transpose fmm
    mFMM, sMatrices, sLU, buf = ParticleScattering.prepare_fmm_reusal_φs(k0,
                                    kin, P, shapes, centers, ids, fmm_options)
    v1 = 5*rand(ComplexF64, M^2*(2P+1))
    v2 = rand(ComplexF64, M^2*(2P+1))
    o1 = Array{ComplexF64}(undef, M^2*(2P+1))
    o2 = Array{ComplexF64}(undef, M^2*(2P+1))
    ParticleScattering.FMM_mainMVP_pre!(o1, v1, sMatrices, φs, ids, P, mFMM,
        buf.pre_agg, buf.trans)
    res1 = transpose(v2)*o1
    ParticleScattering.FMM_mainMVP_transpose!(o2, v2, sMatrices, φs, ids, P,
        mFMM, buf.pre_agg, buf.trans)
    res2 = transpose(v1)*o2
    @test res1 ≈ res2
end
