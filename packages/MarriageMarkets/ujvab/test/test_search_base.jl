# uses variables from setup_tests.jl

### Verifications: basic Shimer-Smith model ###

"""
Element-by-element calculation of steady state flow equations

```julia
mres = (δ .+ ψ_m) .* ℓ_m - u_m .* ((δ .+ ψ_m) + λ * (α * u_f))
fres = (δ .+ ψ_f) .* ℓ_f - u_f .* ((δ .+ ψ_f) + λ * (α' * u_m))
```
"""
function sse_base(M::SearchMatch)

	mres = similar(M.ℓ_m)
	fres = similar(M.ℓ_f)
	
	for i in 1:length(M.ℓ_m)
		mres[i] = (M.δ + M.ψ_m[i]) * M.ℓ_m[i] - M.u_m[i] * ((M.δ + M.ψ_m[i]) + M.λ * dot(M.α[i,:], M.u_f))
	end
	for j in 1:length(M.ℓ_f)
		fres[j] = (M.δ + M.ψ_f[j]) * M.ℓ_f[j] - M.u_f[j] * ((M.δ + M.ψ_f[j]) + M.λ * dot(M.α[:,j], M.u_m))
	end
	return mres, fres
end

"""
Element-by-element calculation of value function equations
```julia
mres = 2*v_m - λ * (αS * u_f)
fres = 2*v_f - λ * (αS' * u_m),
```
where `αS = α .* s/(r+δ+ψ_m(x)+ψ_f(y))`.
"""
function vf_base(M::SearchMatch)

	mres = similar(M.v_m)
	fres = similar(M.v_f)

	for i in 1:length(M.v_m)
		mres[i] = 2*M.v_m[i] - M.λ * dot(M.α[i,:] .* M.s[i,:] ./ (M.r+M.δ+M.ψ_m[i].+M.ψ_f), M.u_f)
	end
	for j in 1:length(M.v_f)
		fres[j] = 2*M.v_f[j] - M.λ * dot(M.α[:,j] .* M.s[:,j] ./ (M.r+M.δ+M.ψ_f[j].+M.ψ_m), M.u_m)
	end
	return mres, fres
end

function surplus_base(M::SearchMatch)
	s = similar(M.h)

	for i in 1:length(M.v_m), j in 1:length(M.v_f)
		s[i,j] = M.h[i,j] - M.v_m[i] - M.v_f[j]
	end

	return s
end


### Tests: basic Shimer-Smith model ###

# check convergence
msse, fsse = sse_base(symm)
mvf, fvf = vf_base(symm)
α_err = symm.α .- convert(Array{Float64}, (surplus_base(symm) .> 0.0))

# valid solution
@test msse ≈ zero(msse) atol=1e-7 #market equilibrium: single men did not converge
@test fsse ≈ zero(fsse) atol=1e-7 #market equilibrium: single women did not converge
@test mvf ≈ zero(mvf) atol=1e-7 #matching equilibrium: man values did not converge
@test fvf ≈ zero(fvf) atol=1e-7 #matching equilibrium: woman values did not converge
@test α_err == zero(α_err) #matching equilibrium: match probabilities α did not converge

# symmetry
@test symm.v_m ≈ symm.v_f #expected symmetry of values
@test symm.u_m ≈ symm.u_f #expected symmetry of singles
@test symm.α ≈ symm.α' #expected symmetry of matching
