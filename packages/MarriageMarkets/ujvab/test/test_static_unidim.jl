pam_implied_pop_m, pam_implied_pop_f = eqm_consistency(pam.surplus, pam.msingle, pam.fsingle)
nam_implied_pop_m, nam_implied_pop_f = eqm_consistency(nam.surplus, nam.msingle, nam.fsingle)

# ensure convergence to valid equilibrium
@testset "validity of equilibrium population measures" begin
	match_tol = 1e-12
	@test pam.matches ≈ match_matrix(pam.surplus, pam.msingle, pam.fsingle) atol = match_tol
	@test pam_implied_pop_m ≈ pam.mdist atol = match_tol
	@test pam_implied_pop_f ≈ pam.fdist atol = match_tol

	@test nam.matches ≈ match_matrix(nam.surplus, nam.msingle, nam.fsingle) atol = match_tol
	@test nam_implied_pop_m ≈ nam.mdist atol = match_tol
	@test nam_implied_pop_f ≈ nam.fdist atol = match_tol
end

# verify that super/sub-modularity of production implies positive/negative assortative matching.
# sum of diag corners greater than sum of anti-diag corners
@testset "positive and negative assortativity" begin
	@test pam.matches[1,1] + pam.matches[end,end] > pam.matches[1,end] + pam.matches[end,1]
	@test nam.matches[1,1] + nam.matches[end,end] < nam.matches[1,end] + nam.matches[end,1]
end

# symmetry
@testset "symmetry of matches and singles" begin
	@test pam.matches ≈ pam.matches'
	@test pam.msingle ≈ pam.fsingle
end

