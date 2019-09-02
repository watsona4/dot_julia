# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/MortarContact2DAD.jl/blob/master/LICENSE

using FEMBase, MortarContact2DAD, Test
using MortarContact2DAD: get_slave_dofs, get_master_dofs
using MortarContact2DAD: project_from_master_to_slave_ad, project_from_slave_to_master_ad

X = Dict(
    1 => [0.0, 0.0],
    2 => [1.0, 0.0],
    3 => [0.0, 1.0],
    4 => [1.0, 1.0])

u = Dict(
    1 => [0.0, 0.0],
    2 => [0.0, 0.0],
    3 => [0.0, 0.0],
    4 => [0.0, 0.0])

slave = Element(Seg2, [1, 2])
master = Element(Seg2, [3, 4])
update!([slave, master], "geometry", X)
update!([slave, master], "displacement", u)
update!(slave, "normal", ([0.0, 1.0], [0.0, 1.0]))
problem = Problem(Mortar2DAD, "test problem", 2, "displacement")
add_slave_elements!(problem, [slave])
add_master_elements!(problem, [master])
problem.assembly.u = zeros(8)
problem.assembly.la = zeros(8)
assemble!(problem, 0.0)
C1_expected = 1/6*[
               2.0 0.0 1.0 0.0 -2.0 0.0 -1.0 0.0
               0.0 2.0 0.0 1.0 0.0 -2.0 0.0 -1.0
               1.0 0.0 2.0 0.0 -1.0 0.0 -2.0 0.0
               0.0 1.0 0.0 2.0 0.0 -1.0 0.0 -2.0]
C1 = problem.assembly.C1
C2 = problem.assembly.C2
@test isapprox(C1, C2)
@test isapprox(C1, C1_expected)

@test_throws Exception add_elements!(problem, [slave])
@test get_slave_dofs(problem) == [1, 2, 3, 4]
@test get_master_dofs(problem) == [5, 6, 7, 8]
x1 = slave("geometry", 0.0)
n1 = slave("normal", 0.0)
xm = 1/3*(X[3]+X[4])
xs = 1/3*(X[1]+X[2])
@test_throws ErrorException project_from_master_to_slave_ad(slave, x1, n1, xm, 0.0; tol=0.0, max_iterations=1)
x1 = [0.5, 0.0]
n1 = [0.0, 1.0]
x2 = master("geometry", 0.0)
@test_throws ErrorException project_from_slave_to_master_ad(master, x1, n1, x2, 0.0; tol=0.0, max_iterations=1)
