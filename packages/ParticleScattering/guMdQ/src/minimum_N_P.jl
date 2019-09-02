"""
	minimumN(kout, kin, shape_function; tol = 1e-9, N_points = 10_000,
        N_start = 400, N_min = 100, N_max = 1_000) -> N, err

Return the minimum `N` necessary (i.e. `2N` nodes) to achieve error of at most
`tol` in the electric field for a `ShapeParams` inclusion created by
`shape_function(N)` which is filled with material of wavenumber `kin` and
surrounded by free space with wavenumber `k0`.
Error is calculated on `N_points` points on the scattering disk (`s.R`), by
assuming a fictitious line source and comparing its field to that produced
by the resulting potential densities.

Since the error scales with \$N^{-3}\$ for moderate wavelengths and errors, we
estimate `N` using the error of `N_start`, then binary search based on that
guess between `N_min` and `N_max`.
"""
function minimumN(kout, kin, shape_function; tol = 1e-9, N_points = 10_000, N_start = 400, N_min = 100, N_max = 1_000)
    # we know that in general err(N) = a/N^3
    #estimate a = err1*N1^3, then N2 = (a/err2)^(1/3) = N1*(err1/err2)^(1/3)
    #assumes unit line source at (0,0), unit plane wave outside

    s = shape_function(N_max) #just for radius
    err_points = [s.R*f(i*2*pi/N_points) for i=0:(N_points-1), f in (cos,sin)]
    E_ana = (0.25im*besselh(0, 1, kout*s.R))*ones(Complex{Float64}, N_points)
    E_comp = Array{Complex{Float64}}(undef, N_points)

    N = N_start
    err_start = minimumN_helper(N, kout, kin, shape_function, err_points, E_comp, E_ana)
    #if starting point was too good, it can be our new max
    err_start < tol && (N_max = min(N_start,N_max))

    N = round(Int, N_start*(err_start/tol)^(1/3))
    N = max(N, N_min)

    err = minimumN_helper(N, kout, kin, shape_function, err_points, E_comp, E_ana)

    if err > tol
        if N > N_max
            @warn("minimumN: Cannot enter binary search mode.")
        else
            @warn("minimumN: Entering binary search mode in [$N,$N_max].")
            N, err = binarySearch(N_ -> -minimumN_helper(N_, kout, kin,
                shape_function, err_points, E_comp, E_ana), -tol, N, N_max)
        end
        err > tol && @warn("minimumN: Failed to find err(N) < tol.")
    elseif err < tol
		if N == N_min
			return N,err
		end
        @warn("minimumN: Entering binary search in [$N_min,$N].")
        N, err = binarySearch(N_ -> -minimumN_helper(N_, kout, kin,
                    shape_function, err_points, E_comp, E_ana), -tol, N_min, N)
    end
    return N, err
end

function minimumN_helper(N, kout, kin, shape_function, err_points, E_comp, E_ana)
    #helper function for computing error for given N
    s = shape_function(N)
    mu_sigma = solvePotential_forError(kin, kout, s, [0.0 0.0], [1], 0.0)

    E_comp[:] = scatteredfield(mu_sigma, kout, s, err_points)
    this_err = norm(E_ana-E_comp)/norm(E_ana)
end

#TODO: similar minimumP for circles, comparing perhaps to collection of line sources

"""
	minimumP(k0, kin, s::ShapeParams; tol = 1e-9, N_points = 10_000, P_min = 1,
        P_max = 60, dist = 2) -> P, errP

Return the minimum `P` necessary to achieve error of at most `tol` in the
electric field, when compared to that obtained with `2N` discretization, for a
`ShapeParams` inclusion filled with material of wavenumber `kin` and surrounded
by free space with wavenumber `k0`.
Error is calculated on `N_points` points on a disk of radius `dist*s.R`.

Uses binary search between `P_min` and `P_max`.
"""
function minimumP(k0, kin, s::ShapeParams; tol = 1e-9, N_points = 10_000, P_min = 1, P_max = 60, dist = 2.0)
	err_points = [dist*s.R*f(i*2*pi/N_points) for i=0:(N_points-1), f in (cos,sin)]
	@warn("""minimumP: Calculating at $dist*R, thus implicitly assuming all scatterers have same radius and we do not care about closer implications.""")

    #compute direct solution for comparison
    inner = get_potentialPW(k0, kin, s, 0.0)
    E_quadrature = scatteredfield(inner, k0, s, err_points)
    E_multipole = Array{Complex{Float64}}(undef, N_points)

    P, errP = binarySearch(P_ -> -minimumP_helper(k0, kin, s, P_,
		N_points, err_points, E_quadrature, E_multipole), -tol, P_min, P_max)
end

function minimumP_helper(k0, kin, s, P, N_points, err_points, E_quadrature, E_multipole)
    #helper function for computing error for given P
    E_multipole[:] .= 0.0
	sp = ScatteringProblem([s],[1],[0.0 0.0],[0.0])
    beta_p,inn = solve_particle_scattering(k0, kin, P, sp, PlaneWave(0.0),
		verbose = false)
    scattered_field_multipole!(E_multipole, k0, beta_p, P, [0.0 0.0], [1],
		err_points, 1:N_points)
    this_err = norm(E_quadrature - E_multipole)/norm(E_quadrature)
end
