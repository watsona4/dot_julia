# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/MortarContact2D.jl/blob/master/LICENSE

using FEMBase, MortarContact2D, Test
using MortarContact2D: calculate_normals,
                       project_from_master_to_slave,
                       project_from_slave_to_master

X = Dict(
    1 => [0.0, 1.0],
    2 => [5/4, 1.0],
    3 => [2.0, 1.0],
    4 => [0.0, 1.0],
    5 => [3/4, 1.0],
    6 => [2.0, 1.0])
mel1 = Element(Seg2, [1, 2])
mel2 = Element(Seg2, [2, 3])
sel1 = Element(Seg2, [4, 5])
sel2 = Element(Seg2, [5, 6])
update!([mel1, mel2, sel1, sel2], "geometry", X)
master_elements = [mel1, mel2]
slave_elements = [sel1, sel2]
normals = calculate_normals(slave_elements, 0.0)
update!(slave_elements, "normal", 0.0 => normals)

X1 = [0.0, 1.0]
n1 = [0.0, 1.0]
xi2 = project_from_slave_to_master(mel1, X1, n1, 0.0)
@test isapprox(xi2, -1.0)

X1 = [0.75, 1.0]
n1 = [0.00, 1.0]
xi2 = project_from_slave_to_master(mel1, X1, n1, 0.0)
@test isapprox(xi2, 0.2)

X2 = mel1("geometry", xi2, 0.0)
@test isapprox(X2, [3/4, 1.0])

X2 = [0.0, 1.0]
xi1 = project_from_master_to_slave(sel1, X2, 0.0)
@test isapprox(xi1, -1.0)
X2 = [1.25, 1.00]
xi1 = project_from_master_to_slave(sel1, X2, 0.0)
X1 = sel1("geometry", xi1, 0.0)
@test isapprox(X1, [5/4, 1.0])

X = Dict(
    1 => [0.0, 0.0],
    2 => [0.0, 1.0],
    3 => [0.0, 1.0],
    4 => [0.0, 0.0])

sel1 = Element(Seg2, [1, 2])
mel1 = Element(Seg2, [3, 4])
update!([sel1, mel1], "geometry", X)
slave_elements = [sel1]
normals = calculate_normals(slave_elements, 0.0)
update!(slave_elements, "normal", 0.0 => normals)

X2 = mel1("geometry", (-1.0, ), 0.0)
xi = project_from_master_to_slave(sel1, X2, 0.0)
@test isapprox(xi, 1.0)

X2 = mel1("geometry", (1.0, ), 0.0)
xi = project_from_master_to_slave(sel1, X2, 0.0)
@test isapprox(xi, -1.0)

X1 = sel1("geometry", (-1.0, ), 0.0)
n1 = sel1("normal", (-1.0, ), 0.0)
xi = project_from_slave_to_master(mel1, X1, n1, 0.0)
@test isapprox(xi, 1.0)

X1 = sel1("geometry", (1.0, ), 0.0)
n1 = sel1("normal", (1.0, ), 0.0)
xi = project_from_slave_to_master(mel1, X1, n1, 0.0)
@test isapprox(xi, -1.0)

@test_throws Exception project_from_master_to_slave(sel1, [0.0, 0.0], 0.0; tol=0.0)
@test_throws Exception project_from_slave_to_master(mel1, [0.0, 1.0], [-1.0, 0.0], 0.0; tol=0.0)
