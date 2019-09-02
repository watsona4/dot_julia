# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/HeatTransfer.jl/blob/master/LICENSE

## Assembling stiffness matrix and force vector for 2d heat problem

using FEMBase, HeatTransfer, Test, SparseArrays

X = Dict(
    1 => [0.0,0.0],
    2 => [1.0,0.0],
    3 => [1.0,1.0],
    4 => [0.0,1.0])

T = Dict(
    1 => 0.0,
    2 => 0.0,
    3 => 0.0,
    4 => 0.0)

element = Element(Quad4, [1, 2, 3, 4])
update!(element, "geometry", X)
update!(element, "temperature", 0.0 => T)
update!(element, "thermal conductivity", 6.0)
update!(element, "heat source", 4.0)

problem = Problem(PlaneHeat, "test problem", 1)
add_elements!(problem, [element])
assemble!(problem, 0.0)
K = Matrix(sparse(problem.assembly.K))
f = Vector(sparse(problem.assembly.f)[:])
K_expected = [
               4.0 -1.0 -2.0 -1.0
              -1.0  4.0 -1.0 -2.0
              -2.0 -1.0  4.0 -1.0
              -1.0 -2.0 -1.0  4.0
             ]
f_expected = [1.0; 1.0; 1.0; 1.0]
@test isapprox(K, K_expected)
@test isapprox(f, f_expected)
@test get_unknown_field_name(problem) == "temperature"
