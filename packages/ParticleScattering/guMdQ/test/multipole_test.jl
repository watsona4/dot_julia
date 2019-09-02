@testset "multipole" begin
    #let's check that rotation works properly
    k0 = 0.1
    kin = 100k0
    λ0 = 2π/k0
    θ_i = 0.0

    N = 1000
    P = 5
    shapes = [squircle(0.2λ0, N)]
    centers = [-1.5λ0 0; 1.5λ0 0]
    Ns = size(centers,1)
    φs = [0.0; 0.23]
    ids = ones(Int, Ns)
    sp = ScatteringProblem(shapes, ids, centers, φs)
    points = λ0*[5 0; -2 3]

    verify_min_distance(shapes, centers, ids, points)
    β1, σ1 = solve_particle_scattering(k0, kin, P, sp, PlaneWave(θ_i);
        get_inner = true, verbose = false)
    Ez1 = scattered_field_multipole(k0, β1, centers, points)

    #now rotate everything by some angle and compare
    θ_r = 1.23#2π*rand()
    #notation is transposed due to structure of centers
    shapes2 = [squircle(0.2λ0, N); CircleParams(15)] #no effect,for extra code coverage
    centers2 = centers*[cos(θ_r) sin(θ_r); -sin(θ_r) cos(θ_r)]
    φs2 = θ_r .+ φs
    sp2 = ScatteringProblem(shapes2, ids, centers2, φs2)
    points2 = points*[cos(θ_r) sin(θ_r); -sin(θ_r) cos(θ_r)]

    β2, σ2 = solve_particle_scattering(k0, kin, P, sp2, PlaneWave(θ_i + θ_r);
        get_inner = true, verbose = true)
    Ez2 = scattered_field_multipole(k0, β2, centers2, points2)

    @test Ez1 ≈ Ez2
    β2_r = copy(β2)
    for ic = 1:Ns, p = -P:P
        β2_r[(ic-1)*(2P+1) + p + P + 1] *= exp(1.0im*θ_r*p)
    end
    @test β1 ≈ β2_r
    @test σ1 ≈ σ2
end

@testset "circle" begin
    k0 = 1
    kin = 0.1
    R = 0.2
    P = 10
    S, gamma = ParticleScattering.circleScatteringMatrix(k0, kin, R, P; gamma = true)
    center = [0 2R]
    points = center .+ [0 0.5R; 0.1R -0.2R]
    E1 = ParticleScattering.innerFieldCircle(kin, gamma, center[1,:], points)
    E2 = ParticleScattering.innerFieldCircle(kin, gamma, center[1,:], points[1,:])
    @test E1[1] == E2
end
