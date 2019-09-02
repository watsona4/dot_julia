@testset "scattered field" begin
    k0 = 0.1
    kin = 3k0
    θ_i = rand()*2π

    N = 1000
    shapes = [squircle(1, N);
            rounded_star(0.8, 0.2, 3, N);
            rounded_star(0.75, 0.25, 5, N);
            ellipse(0.2, 0.9, N)]
    for s in shapes
        sigma_mu = get_potentialPW(k0, kin, s, θ_i)
        dx = 2*norm(s.ft[1,:] - s.ft[2,:])
        #normal vector
        nvec = [s.dft[:,2] -s.dft[:,1]]./hypot.(s.dft[:,1],s.dft[:,2])
        p_in = s.ft - nvec*dx
        p_out = s.ft + nvec*dx
        u_in = scatteredfield(sigma_mu, kin, s, p_in)
        u_out = scatteredfield(sigma_mu, k0, s, p_out)
        #some error is allowed as this quadrature is imprecise close to the boundary
        u_inc = uinc(k0, s.ft, PlaneWave(θ_i))
        @test norm(u_inc + u_out - u_in)/norm(u_inc) < 1e-3
    end
end
