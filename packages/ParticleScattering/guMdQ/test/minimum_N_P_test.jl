#compare to precomputed values
k0 = 0.3
kin = 0.5k0
tols = [1e-9;
        1e-7;
        1e-5]
N_res = [250;
         100;
         313]

@testset "minimum N" begin
    shape_funs =   [N -> squircle(1, N);
                    N -> rounded_star(0.08, 0.02, 3, N);
                    N -> rounded_star(25, 5, 5, N)]

    for (i,f) in enumerate(shape_funs)
        N, err = minimumN(k0, kin, f; tol = tols[i], N_points = 20_000,
                    N_start = 250, N_min = 100, N_max = 400)
        @test N == N_res[i] && err <= tols[i]
    end
end

P_res = [13;
         9;
         34]
dists = [2.0;
    	 2.0;
         1.0]
@testset "minimum P" begin
    shapes = [squircle(1, N_res[1]);
                rounded_star(0.08, 0.02, 3, N_res[2]);
                rounded_star(25, 5, 5, N_res[3])]

    for i in eachindex(shapes)
        P, err = minimumP(k0, kin, shapes[i]; tol = tols[i], N_points = 20_000,
                    P_min = 1, P_max = 60, dist = dists[i])
        @test P == P_res[i] && err <= tols[i]
    end
end
