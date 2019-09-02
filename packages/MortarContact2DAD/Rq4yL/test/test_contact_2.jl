# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/MortarContact2DAD.jl/blob/master/LICENSE

using MortarContact2DAD, Test

# Matching mesh, undeformed, gap = 1.0 between surfaces

X = Dict(
    1 => [0.0, 0.0],
    2 => [0.0, 2.0],
    3 => [1.0, 2.0],
    4 => [1.0, 0.0])

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
push!(problem.properties.always_in_contact, 1, 2)
problem.properties.rotate_normals = true
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
 1.0  0.0  0.0  0.0   0.0   0.0  -1.0   0.0
 0.0  1.0  0.0  0.0   0.0   0.0   0.0  -1.0
 0.0  0.0  1.0  0.0  -1.0   0.0   0.0   0.0
 0.0  0.0  0.0  1.0   0.0  -1.0   0.0   0.0]
C2_expected = [
 1.0   0.5  0.0 -0.5   0.0  0.0  -1.0  0.0
 0.0   0.0  0.0  0.0   0.0  0.0   0.0  0.0
 0.0   0.5  1.0 -0.5  -1.0  0.0   0.0  0.0
 0.0   0.0  0.0  0.0   0.0  0.0   0.0  0.0]
D_expected = [
 0.0   0.0  0.0   0.0  0.0  0.0  0.0  0.0
 0.0  -1.0  0.0   0.0  0.0  0.0  0.0  0.0
 0.0   0.0  0.0   0.0  0.0  0.0  0.0  0.0
 0.0   0.0  0.0  -1.0  0.0  0.0  0.0  0.0]
@test isapprox(C1, C1_expected)
@test isapprox(K, zeros(4, 8))
@test isapprox(f, zeros(4))
@test isapprox(g, [1.0, 0.0, 1.0, 0.0])
@test isapprox(C2, C2_expected)
@test isapprox(D, D_expected)
