# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/HeatTransfer.jl/blob/master/LICENSE

## Use of flux boundary condition in 2d heat problem

using FEMBase, Test, HeatTransfer, SparseArrays

X = Dict(
    1 => [0.0,0.0],
    2 => [1.0,0.0])

T = Dict(
    1 => 0.0,
    2 => 0.0)

element = Element(Seg2, [1, 2])
update!(element, "geometry", X)
update!(element, "temperature", 0.0 => T)
update!(element, "heat flux", 2.0)
problem = Problem(PlaneHeat, "test problem", 1)
add_elements!(problem, [element])
assemble!(problem, 0.0)
f = Vector(sparse(problem.assembly.f)[:])
f_expected = [1.0; 1.0]
@test isapprox(f, f_expected)
