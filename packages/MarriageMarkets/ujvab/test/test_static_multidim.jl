# uses variables from setup_tests.jl

sym_implied_pop_m, sym_implied_pop_f = eqm_consistency(mgmkt.surplus, mgmkt.msingle, mgmkt.fsingle)
asym_implied_pop_m, asym_implied_pop_f = eqm_consistency(mgmkt2.surplus, mgmkt2.msingle, mgmkt2.fsingle)

# ensure convergence to valid equilibrium
@testset "validity of equilibrium population measures" begin
	match_tol = 1e-12
	@test mgmkt.matches ≈ match_matrix(mgmkt.surplus, mgmkt.msingle, mgmkt.fsingle) atol = match_tol
	@test sym_implied_pop_m ≈ mgmkt.mdist atol = match_tol
	@test sym_implied_pop_f ≈ mgmkt.fdist atol = match_tol

	@test mgmkt2.matches ≈ match_matrix(mgmkt2.surplus, mgmkt2.msingle, mgmkt2.fsingle) atol = match_tol
	@test asym_implied_pop_m ≈ mgmkt2.mdist atol = match_tol
	@test asym_implied_pop_f ≈ mgmkt2.fdist atol = match_tol
end

# check symmetry
@test mgmkt.msingle ≈ mgmkt.fsingle

# check that supermodular surplus results in positive assortative matching
@test mgmkt2.matches[1,1,1,1] + mgmkt2.matches[end,end,end,end] > mgmkt2.matches[1,1,end,end] + mgmkt2.matches[end,end,1,1]
