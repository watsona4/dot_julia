# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/HeatTransfer.jl/blob/master/LICENSE

## Use of flux boundary condition in 3d heat problem

using FEMBase, Test, HeatTransfer, SparseArrays

X = Dict(
    1 => [0.0,0.0,0.0],
    2 => [1.0,0.0,0.0],
    3 => [0.0,1.0,0.0])

T = Dict(
    1 => 0.0,
    2 => 0.0,
    3 => 0.0)

element = Element(Tri3, [1, 2, 3])
update!(element, "geometry", X)
update!(element, "temperature", T)
update!(element, "heat flux", 6.0)
problem = Problem(Heat, "test problem", 1)
add_elements!(problem, [element])
assemble!(problem, 0.0)
f = Vector(sparse(problem.assembly.f)[:])
f_expected = [1.0; 1.0; 1.0]
@test isapprox(f, f_expected)
