# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/MortarContact2D.jl/blob/master/LICENSE

# Simple coupling interface of four elements

using FEMBase, MortarContact2D, Test
using MortarContact2D: get_slave_dofs, get_master_dofs,
                       get_mortar_matrix_D, get_mortar_matrix_M,
                       get_mortar_matrix_P

# Slave side coordinates:
Xs = Dict(
    1 => [0.0, 1.0],
    2 => [1.0, 1.0],
    3 => [2.0, 1.0])

# Master side coordinates:
Xm = Dict(
    4 => [0.0, 1.0],
    5 => [5/4, 1.0],
    6 => [2.0, 1.0])

# Define elements, update geometry:
X = merge(Xm , Xs)
es1 = Element(Seg2, [1, 2])
es2 = Element(Seg2, [2, 3])
em1 = Element(Seg2, [4, 5])
em2 = Element(Seg2, [5, 6])
elements = [es1, es2, em1, em2]
update!(elements, "geometry", X)

# Define new problem `Mortar2D`, coupling elements using mortar methods
problem = Problem(Mortar2D, "test interface", 1, "u")
@test_throws ErrorException add_elements!(problem, [es1, es2])
add_slave_elements!(problem, [es1, es2])
add_master_elements!(problem, [em1, em2])

# Assemble problem
assemble!(problem, 0.0)
s = get_slave_dofs(problem)
m = get_master_dofs(problem)
@test s == [1, 2, 3]
@test m == [4, 5, 6]

P = get_mortar_matrix_P(problem)
D = get_mortar_matrix_D(problem)
M = get_mortar_matrix_M(problem)

# From my thesis
D_expected = [1/3 1/6 0; 1/6 2/3 1/6; 0 1/6 1/3]
M_expected = [11/30 2/15 0; 41/160 13/20 3/32; 1/480 13/60 9/32]
P_expected = 1/320*[329 -24 15; 46 304 -30; -21 56 285]

# Results:

@test isapprox(D, D_expected)
@test isapprox(M, M_expected)
@test isapprox(P, P_expected)
