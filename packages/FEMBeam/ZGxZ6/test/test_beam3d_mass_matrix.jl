# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/FEMBeam.jl/blob/master/LICENSE

using FEMBeam
using FEMBase.Test

X = Dict(
    1 => [0.0, 0.0, 0.0],
    2 => [3.0, 0.0, 0.0])

beam = Element(Seg2, [1, 2])

update!(beam, "geometry", X)
update!(beam, "density", 100.0)
update!(beam, "youngs modulus", 100.0e6)
update!(beam, "shear modulus", 80.0e6)
update!(beam, "cross-section area", 0.25)
update!(beam, "torsional moment of inertia 1", 1.5e-4)
update!(beam, "torsional moment of inertia 2", 1.5e-4)
update!(beam, "polar moment of inertia", 3.0e-4)
update!(beam, "normal", [0.0, 0.0, 1.0])
problem = Problem(Beam, "beam", 6)
add_elements!(problem, [beam])
assemble!(problem, 0.0)

# ABAQUS uses cubic interpolation in axial direction and our implementation
# uses linear; for that reasons results will differ for dofs 1 and 7
axial_dofs = [1, 7]
K = Matrix(sparse(problem.assembly.K))
K[axial_dofs, axial_dofs] *= 1.2
K_expected = read_mtx_from_file(@test_resource("model_STIF1.mtx"))
if !isapprox(K, K_expected)
    println("Difference in stiffness matrix compared to ABAQUS:")
    println("\n\nK(ABAQUS)")
    display(K_expected)
    println("\n\nK(JuliaFEM)")
    display(K)
    K_diff = K - K_expected
    K_diff[abs.(K_diff) .< 1.0e-9] = 0.0
    println("\n\nK(Difference)")
    display(K_diff)
    println("\n\n")
end
@test isapprox(K, K_expected)

# ABAQUS uses cubic interpolation in axial direction and our implementation
# uses linear; for that reasons results will differ for dofs 1 and 7
M = Matrix(sparse(problem.assembly.M))
M[axial_dofs, axial_dofs] += 2.75*[1.0 -1.0; -1.0 1.0]
M_expected = read_mtx_from_file(@test_resource("model_MASS1.mtx"))
if !isapprox(M, M_expected)
    println("Difference in mass matrix compared to ABAQUS:")
    println("\n\nM(ABAQUS)")
    display(M_expected)
    println("\n\nM(JuliaFEM)")
    display(M)
    M_diff = M - M_expected
    M_diff[abs.(M_diff) .< 1.0e-9] = 0.0
    println("\n\nM(Difference)")
    display(M_diff)
    println("\n\n")
end
@test isapprox(M, M_expected)
