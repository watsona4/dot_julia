"""
	solve_particle_scattering_FMM(k0, kin, P, sp::ScatteringProblem, u::Einc, opt::FMMoptions; plot_res = false, get_inner = true, verbose = true) -> result, inner

Solve the scattering problem `sp` with outer wavenumber `k0`, inner wavenumber
`kin`, `2P+1` cylindrical harmonics per inclusion and incident TM field
`u`. Utilizes FMM with options `opt` to solve multiple-scattering equation.
Returns the cylindrical harmonics basis `beta` along with convergence data in
`result`. `inner` contains potential densities (in case of arbitrary inclusion)
or inner cylindrical coefficients (in case of circular).

`plot_res` controls plotting of the residual. Inner coefficients are calculated
only if `get_inner` is true, and timing is printed if `verbose` is true.
"""
function solve_particle_scattering_FMM(k0, kin, P, sp::ScatteringProblem, u::Einc, opt::FMMoptions; plot_res = false, get_inner = true, verbose = true)
	@assert opt.FMM "opt.FMM is disabled, set to true"
	shapes = sp.shapes;	ids = sp.ids; centers = sp.centers; φs = sp.φs
    Ns = size(sp)
    groups, boxSize = divideSpace(centers, opt)
    P2, Q = FMMtruncation(opt.acc, boxSize, k0)
    verbose && println("FMM solution timing:")
    dt0 = @elapsed begin
    	mFMM = FMMbuildMatrices(k0, P, P2, Q, groups, centers, boxSize, tri=true)
    end

    dt1 = @elapsed begin
    	scatteringMatrices,innerExpansions = particleExpansion(k0, kin, shapes, P, ids)
    end

    dt2 = @elapsed begin
	    #construct rhs
	    rhs = u2α(k0, u, centers, P)
	    for ic = 1:Ns
	        rng = (ic-1)*(2*P+1) .+ (1:2*P+1)
	        #see if there is a faster alternative
	        if φs[ic] == 0.0
	            rhs[rng] = scatteringMatrices[ids[ic]]*rhs[rng]
	        else
	            #rotate without matrix
	            rotateMultipole!(view(rhs,rng),-φs[ic],P)
	            rhs[rng] = scatteringMatrices[ids[ic]]*rhs[rng]
	            rotateMultipole!(view(rhs,rng),φs[ic],P)
	        end
	    end
	end

    pre_agg_buffer = zeros(Complex{Float64},Q,length(groups))
    trans_buffer = Array{Complex{Float64}}(undef, Q)
    dt3 = @elapsed begin
	    MVP = LinearMap{eltype(rhs)}((output_, x_) -> FMM_mainMVP_pre!(output_,
									x_, scatteringMatrices, φs, ids, P, mFMM,
									pre_agg_buffer, trans_buffer), Ns*(2*P+1),
									Ns*(2*P+1), ismutating = true)
	    result = gmres(MVP, rhs, restart = Ns*(2*P+1), tol = opt.tol, log = true) #no restart, preconditioning
    end

    if get_inner
        #recover full incoming expansion - in sigma_mu terms for parametrized shape,
        #in multipole expansion for circle
        dt4 = @elapsed begin
	        #find LU factorization once for each shape
	        scatteringLU = [lu(scatteringMatrices[i]) for i = 1:length(shapes)]
	        inner = Array{Vector{Complex{Float64}}}(undef, Ns)
	        α_c = Array{Complex{Float64}}(undef, 2*P+1)
	    	for ic = 1:Ns
	    		rng = (ic-1)*(2*P+1) .+ (1:2*P+1)
	            if typeof(shapes[ids[ic]]) == ShapeParams
	                if φs[ic] == 0.0
	                    α_c[:] = scatteringLU[ids[ic]]\result[1][rng]
	                else
	                    rotateMultipole!(α_c, view(result[1],rng), -φs[ic], P)
	                    ldiv!(scatteringLU[ids[ic]], α_c)
	                end
	        		inner[ic] = innerExpansions[ids[ic]]*α_c
	            else
	                inner[ic] = innerExpansions[ids[ic]]*result[1][rng]
	            end
	    	end
        end
    end

    if plot_res
        residual_ = MVP*result[1] - rhs
        println("last residual is empirically: $(norm(residual_)), but result[2].residuals[end] = $(result[2].residuals[end])")
        figure()
        semilogy(transpose(result[2].residuals))
    end
    if verbose
        println("FMM matrix construction: $dt0 s")
        println("Scattering matrix solution: $dt1 s")
        println("RHS construction: $dt2 s")
        println("Iterative process: $dt3 s")
        get_inner && println("Retrieving inner coefficients: $dt4 s")
    end
    get_inner ? (return result, inner) : (return result)
end
