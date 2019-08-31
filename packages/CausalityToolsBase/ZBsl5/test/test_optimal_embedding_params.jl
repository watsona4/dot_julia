x = rand(100)

@test optimal_delay(x) isa Int
@test optimal_delay(x, method = "ac_zero") isa Int
@test optimal_dimension(x, 2, method = "f1nn", method_delay = "mi_min") isa Int
@test optimal_dimension(x, method_delay = "mi_min") isa Int