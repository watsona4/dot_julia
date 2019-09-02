using NLsolve

"""
	StaticMatch(mtypes, ftypes, mdist, fdist, surplus)

Construct a Choo & Siow (2006) marriage market model and solve for the equilibrium.
"""
struct StaticMatch

	# m/f types
	"vector of vectors of values for each of N male traits"
	mtypes::Array{Array{T, 1}, 1} where T <: Real
	"vector of vectors of values for each of L female traits"
	ftypes::Array{Array{T, 1}, 1} where T <: Real

	# m/f masses
	"male masses: I_1 x ... x I_N"
	mdist::Array
	"female masses: J_1 x ... x J_L"
	fdist::Array

	"surplus array: (I_1 x ... x I_N) x (J_1 x ... x J_L)"
	surplus::Array

	# equilibrium
	"masses of single males: I_1 x ... x I_N"
	msingle::Array
	"masses of single females: J_1 x ... x J_L"
	fsingle::Array
	"masses of married couples: (I_1 x ... x I_N) x (J_1 x ... x J_L)"
	matches::Array
	"wife's share of marital surplus: (I_1 x ... x I_N) x (J_1 x ... x J_L)"
	wifeshare::Array

	"Inner constructor solves equilibrium and performs sanity checks"
	function StaticMatch(mtypes::Array{Array{T, 1}, 1} where T <: Real,
		                 ftypes::Array{Array{T, 1}, 1} where T <: Real,
		                 mdist::Array, fdist::Array, surplus::Array)

		# CHECK: masses of m/f must be proper probability distro
		if minimum(mdist) < 0 || minimum(fdist) < 0
			error("invalid type distribution")
		end

		# CHECK: masses of m/f match the number of types
		if ndims(mdist) != length(mtypes) || ndims(fdist) != length(ftypes)
			error("type distributions inconsistent with type vectors")
		end

		# compute equilibrium
		msingle, fsingle, matches = equilibrium(surplus, mdist, fdist)
		wifeshare = surplusdiv(matches, msingle, fsingle) ./ (2 .* surplus)

		# TEST: masses of every match outcome must be strictly positive
		negtol = 0
		if minimum(msingle) < -negtol || minimum(fsingle) < -negtol
			@warn "Non-positive mass of singles."
		end
		if minimum(matches) < -negtol
			@warn "Non-positive match mass."
		end

		# create instance
		new(mtypes, ftypes, mdist, fdist, surplus, msingle, fsingle, matches, wifeshare)
	end # constructor


end # struct


"Outer constructor that takes the production function to build the surplus array"
function StaticMatch(men::Array{Array{T, 1}, 1} where T <: Real, wom::Array{Array{T, 1}, 1} where T <: Real,
	                 mmass::Array, fmass::Array, prodfn::Function)
	# Note: prodfn(man::Vector, woman::Vector)
	surp = generate_surplus(men, wom, mmass, fmass, prodfn)
	return StaticMatch(men, wom, mmass, fmass, surp)
end

"Outer constructor for one dimensional case"
function StaticMatch(men::Vector, wom::Vector,
	                 mmass::Array, fmass::Array, prodfn::Function)
	# augment production function
	g(x::Vector, y::Vector) = prodfn(x[1], y[1])
	return StaticMatch([men,], [wom,], mmass, fmass, g)
end

"Outer constructor for one dimensional males case"
function StaticMatch(men::Vector, wom::Array{Array{T, 1}, 1} where T <: Real,
	                 mmass::Array, fmass::Array, prodfn::Function)
	return StaticMatch([men,], wom, mmass, fmass, prodfn)
end

"Outer constructor for one dimensional females case"
function StaticMatch(men::Array{Array{T, 1}, 1} where T <: Real, wom::Vector,
	                 mmass::Array, fmass::Array, prodfn::Function)
	return StaticMatch(men, [wom,], mmass, fmass, prodfn)
end



"""
Quasi-demand functions

Assuming that surplus is generated from equal gains on both sides.
This is w.l.o.g. as gains and transfers cannot be separately identified.
"""
function demand(surp::Array, transfers::Array, mmass::Array, fmass::Array)

	# un-normalized raw demands (Note: surp is defined in per-person terms)
	m_raw_dmd = exp.(surp .- transfers)
	f_raw_dmd = exp.(surp .+ transfers)

	# total raw demands per sex, by summing over opposite sex
	m_raw_dmd_tot = [sum(m_raw_dmd[i,j] for j in CartesianIndices(fmass)) for i in CartesianIndices(mmass)]
	f_raw_dmd_tot = [sum(f_raw_dmd[i,j] for i in CartesianIndices(mmass)) for j in CartesianIndices(fmass)]

	# solve for singles: normalization factors
	m_sng_dmd = mmass ./ (1 .+ m_raw_dmd_tot)
	f_sng_dmd = fmass ./ (1 .+ f_raw_dmd_tot)

	# normalized demands
	m_dmd = [m_sng_dmd[i] * m_raw_dmd[i,j] for i in CartesianIndices(mmass), j in CartesianIndices(fmass)]
	f_dmd = [f_sng_dmd[j] * f_raw_dmd[i,j] for i in CartesianIndices(mmass), j in CartesianIndices(fmass)]

	return m_sng_dmd, m_dmd, f_sng_dmd, f_dmd
end # demand

"""
Compute equilibrium shares of singles and marriages.

Solves the matching equilibrium by searching for the transfers
(analogous to prices) which clear the market.
"""
function equilibrium(surpl::Array, mmass::Array, fmass::Array)

	"Function to pass to solver to find zero."
	function eqnsys!(res::Array, tx::Array)
		msd, mdmd, fsd, fdmd = demand(surpl, tx, mmass, fmass)
		res .= mdmd .- fdmd
		return res
	end

	#initial guess of transfers/prices
	guess = zero(surpl)

	# NLsolve
	result = nlsolve(eqnsys!, guess, ftol = 1e-16, autodiff = :forward, method = :newton)

	if !converged(result)
		@warn "NLsolve failed to converge to equilibrium. Solver result:"
		@show result
	end

	eqm_transfers = reshape(result.zero, size(surpl))
	singmen, mmatches, singwom, fmatches = demand(surpl, eqm_transfers, mmass, fmass)
	matches = (mmatches .+ fmatches) ./ 2 # average out any approximation error

	return singmen, singwom, matches
end # equilibrium

"Construct production array from function."
function generate_surplus(mtypes::Array{Array{T, 1}, 1} where T <: Real,
                          ftypes::Array{Array{T, 1}, 1} where T <: Real,
                          mmass::Array, fmass::Array, prodfn::Function)
	# get dimensions
	Dm = [length(v) for v in mtypes]
	Df = [length(v) for v in ftypes]

	# initialize arrays
	surp = Array{Float64}(undef, Dm..., Df...)
	gent = Vector{Float64}(undef, length(mtypes)) # one man's vector of traits
	lady = Vector{Float64}(undef, length(ftypes))

	for coord in CartesianIndices(surp)
		for trt in 1:length(mtypes) # loop through traits in coord
			gent[trt] = mtypes[trt][coord[trt]]
		end
		for trt in 1:length(ftypes) # loop through traits in coord
			lady[trt] = ftypes[trt][coord[trt+length(mtypes)]]
		end
		surp[coord] = prodfn(gent, lady)
	end

	return surp
end # generate_surplus

"Wife's consumption out of surplus (aggregate share)."
function surplusdiv(matches::Array, sm::Array, sw::Array)
	return [log(matches[i,j]) - log(sw[j]) for i in CartesianIndices(sm), j in CartesianIndices(sw)]
end # surplusdiv

"Estimate the marital surplus from observed matches and singles."
function estimate_static_surplus(matches::Array, msingle::Array, fsingle::Array)
	return [log(matches[i,j]) - 0.5 * (log(msingle[i]) + log(fsingle[j]))
	        for i in CartesianIndices(msingle), j in CartesianIndices(fsingle)]
end # estimate_static_surplus

