# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/MortarContact2DAD.jl/blob/master/LICENSE

using MortarContact2DAD, Test

# Matching mesh, no gap between surfaces

X = Dict(
    1 => [0.0, 2.0],
    2 => [0.0, 0.0],
    3 => [0.0, 2.0],
    4 => [0.0, 0.0])

u = Dict(
    1 => [0.0, 0.0],
    2 => [0.0, 0.0],
    3 => [0.0, 0.0],
    4 => [0.0, 0.0])

slave = Element(Seg2, [1, 2])
master = Element(Seg2, [3, 4])
update!([slave, master], "geometry", X)
update!([slave, master], "displacement", u)
problem = Problem(Contact2DAD, "test problem", 2, "displacement")
problem.properties.rotate_normals = false
add_slave_elements!(problem, [slave])
add_master_elements!(problem, [master])
problem.assembly.u = zeros(8)
problem.assembly.la = zeros(8)
assemble!(problem, 0.0)

n = slave("normal", 0.0)
@test isapprox(n[1], n[2])
@test isapprox(n[1], [1.0, 0.0])

C1 = Matrix(sparse(problem.assembly.C1, 4, 8))
C2 = Matrix(sparse(problem.assembly.C2, 4, 8))
K = Matrix(sparse(problem.assembly.K, 4, 8))
D = Matrix(sparse(problem.assembly.D, 4, 8))
f = Vector(sparse(problem.assembly.f, 4, 1)[:])
g = Vector(sparse(problem.assembly.g, 4, 1)[:])

C1_expected = [
 1.0  0.0  0.0  0.0  -1.0   0.0   0.0   0.0
 0.0  1.0  0.0  0.0   0.0  -1.0   0.0   0.0
 0.0  0.0  1.0  0.0   0.0   0.0  -1.0   0.0
 0.0  0.0  0.0  1.0   0.0   0.0   0.0  -1.0]
C2_expected = [
 1.0  0.0  0.0  0.0  -1.0  0.0   0.0  0.0
 0.0  0.0  0.0  0.0   0.0  0.0   0.0  0.0
 0.0  0.0  1.0  0.0   0.0  0.0  -1.0  0.0
 0.0  0.0  0.0  0.0   0.0  0.0   0.0  0.0]
@test isapprox(C1, C1_expected)
@test isapprox(C2, C2_expected)
@test isapprox(K, zeros(4, 8))
@test isapprox(f, zeros(4))
@test isapprox(g, zeros(4))

empty!(problem.assembly)
problem.properties.iteration = 0
problem.properties.contact_state_in_first_iteration = :INACTIVE
problem.properties.print_summary = true
assemble!(problem, 0.0)
C2 = Matrix(sparse(problem.assembly.C2, 4, 8))
@test !isapprox(C2, C2_expected)

problem.assembly.u = zeros(0)
problem.assembly.la = zeros(0)
empty!(problem.assembly)
@test_throws Exception assemble!(problem, 0.0)

using MortarContact2DAD: get_slave_dofs, get_master_dofs
@test get_slave_dofs(problem) == [1, 2, 3, 4]
@test get_master_dofs(problem) == [5, 6, 7, 8]
@test_throws Exception add_elements!(problem, [slave])
