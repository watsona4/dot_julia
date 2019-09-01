using Test
using ForestBiometrics

@test limiting_distance(10,12.4,34.0) == "The tree is in"
