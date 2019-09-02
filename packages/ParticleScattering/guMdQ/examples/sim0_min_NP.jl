######################################
## comparing analytical (fictitious sources) and computed fields. minimum N
## routine runs on multiple cores and uses a lot of memory -- reduce max Nvec5,
## Nvecs if necessary
using PyPlot,Distributed,SpecialFunctions
import JLD
addprocs(4)
@everywhere using ParticleScattering
output_dir = homedir()

function unique_subset(N,v,rev = true)
	all(sort(v, rev = rev) .== v) || error("Only handles sorted vectors.")
	v_u = [v[1]]
	N_u = [N[1]]
	prev = v[1]
	for i = 2:length(N)
		if v[i] !== prev
			#encountered new val
			push!(v_u, v[i])
			push!(N_u, N[i])
			prev = v[i]
		end
	end
    N_u,v_u
end
# binary search here is suboptimal since we know that new P is "close" to old one,
# frequently P or P+1
function findMinP(N, errN, shapefun, N_points, k0, kin; P_last = 1, P_max = 100)
	E_multipole = Array{Complex{Float64}}(undef, N_points)
	errP = zeros(Float64, length(errN))
	Pmin = zeros(Int, length(errN))
	for iN in eachindex(errN)
		s = shapefun(N[iN])

		err_points = [2.0*s.R*f(i*2*pi/N_points) for i=0:(N_points-1), f in (cos,sin)]
		#compute direct solution for comparison
		inner = get_potentialPW(k0, kin, s, 0.0)
		E_quadrature = scatteredfield(inner, k0, s, err_points)
		for P = P_last:P_max
			err = ParticleScattering.minimumP_helper(k0, kin, s, P, N_points,
					err_points, E_quadrature, E_multipole)
			if err <= errN[iN]
				errP[iN] = err
				Pmin[iN] = P
				P_last = P
				break
			elseif P == P_max
				@warn("Failed to find P for iN = $iN")
				return Pmin, errP
			end
		end
		display("findMinP: done with iN=$iN/$(length(errN)), matched P=$(Pmin[iN]) with $(errP[iN]) ≤ $(errN[iN])")
	end
	Pmin, errP
end

@everywhere begin
	k0 = 10.0
	kin = 1.5*k0
	l0 = 2π/k0
	a1 = 0.3l0
	a2 = 0.1l0
	N_points = 20_000
	myshapefun5(N) = rounded_star(a1,a2,5,N)
	myshapefun_squircle(N) = squircle(a1+0.5a2,N)
	Nvec5 = unique(round.(Int, 10 .^ range(log10(20), stop=log10(5000), length=200)))
	Nvecs = unique(round.(Int, 10 .^ range(log10(20), stop=log10(5000), length=200)))
end

dt_Nvec5 = @elapsed begin
	s = myshapefun5(400) #just for radius
	err_points = [s.R*f(i*2*pi/N_points) for i=0:(N_points-1), f in (cos,sin)]
	E_ana = (0.25im*besselh(0,1,k0*s.R))*ones(Complex{Float64},N_points)
	E_comp = Array{ComplexF64}(undef, length(E_ana))

	innerfunc1 = function(i)
		ParticleScattering.minimumN_helper(Nvec5[i], k0, kin,
						myshapefun5, err_points, E_comp, E_ana)
	end
	errNvec5 = pmap(innerfunc1, eachindex(Nvec5),
				on_error = ex->(isa(ex, OutOfMemoryError) ? NaN : rethrow(ex)))
	#or
	#errNvec5 = pmap(innerfunc1, eachindex(Nvec5))
end
display("finished calculating minimum N for rounded star in $dt_Nvec5 seconds")
any(isnan.(errNvec5)) && @warn "encountered OutOfMemoryError, some values are NaN"

dt_Nvecs = @elapsed begin
	s = myshapefun_squircle(400) #just for radius
	err_points = [s.R*f(i*2*pi/N_points) for i=0:(N_points-1), f in (cos,sin)]
	E_ana = (0.25im*besselh(0,1,k0*s.R))*ones(Complex{Float64},N_points)
	E_comp = Array{ComplexF64}(undef, length(E_ana))

	innerfunc2 = function(i)
		ParticleScattering.minimumN_helper(Nvecs[i], k0, kin,
						myshapefun_squircle, err_points, E_comp, E_ana)
	end
	errNvecs = pmap(innerfunc2, eachindex(Nvecs),
				on_error = ex->(isa(ex, OutOfMemoryError) ? NaN : rethrow(ex)))
	#or
	#errNvecs = pmap(innerfunc2, eachindex(Nvecs))
end
display("finished calculating minimum N for squircle in $dt_Nvecs seconds")
any(isnan.(errNvecs)) && @warn "encountered OutOfMemoryError, some values are NaN"

N5, errN5 = unique_subset(Nvec5, errNvec5)
Ns, errNs = unique_subset(Nvecs, errNvecs)
inds = something(findfirst(errNs .< 5e-10), length(errNs))
ind5 = something(findfirst(errN5 .< 5e-10), length(errN5))
N5 = N5[1:ind5]
Ns = Ns[1:inds]
errN5 = errN5[1:ind5]
errNs = errNs[1:inds]

P5,errP5 = findMinP(N5, errN5, myshapefun5, N_points, k0, kin)
Ps,errPs = findMinP(Ns, errNs, myshapefun_squircle, N_points, k0, kin)

JLD.@save joinpath(output_dir, "mindata.jld") k0 kin l0 a1 a2 N5 errN5 Ns errNs Ps errPs P5 errP5

##################################################
#plot
fig = figure(figsize=[3.5, 2.5])
loglog(errN5, N5, "b-.", linewidth=1,
		label="\$N_{\\mathrm{min}} \\, \\mathrm{(star)}\$")
loglog(errNs, Ns, "r:", linewidth=1,
		label="\$N_{\\mathrm{min}} \\, \\mathrm{(squircle)}\$")
loglog(errN5, P5, "tab:green", linewidth=1,
		label="\$P_{\\mathrm{min}} \\, \\mathrm{(star)}\$")
loglog(errNs, Ps, "k--", linewidth=1,
		label="\$P_{\\mathrm{min}} \\, \\mathrm{(squircle)}\$")
xlim([5e-10;1e-1])
xlabel("\$\\Delta \\, u\$")
tick_params(which="both", direction="in")
legend(fontsize=8)
grid()
