# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/MortarContact2D.jl/blob/master/LICENSE

# Construct discrete coupling operator between two elements and eliminate
# boundary conditions from global matrix assembly. Thesis, p. 73.

using FEMBase, MortarContact2D, Test

X = Dict(
    1 => [1.0, 2.0],
    2 => [3.0, 2.0],
    3 => [2.0, 2.0],
    4 => [0.0, 2.0],
    5 => [3.0, 4.0],
    6 => [1.0, 4.0],
    7 => [0.0, 0.0],
    8 => [2.0, 0.0])

slave = Element(Seg2, [1, 2])
master = Element(Seg2, [3, 4])
elements = [slave, master]
update!(elements, "geometry", X)

problem = Problem(Mortar2D, "test interface", 2, "displacement")
add_slave_elements!(problem, [slave])
add_master_elements!(problem, [master])
assemble!(problem, 0.0)

K_SS = K_MM = [
 180.0   81.0  -126.0   27.0
  81.0  180.0   -27.0   36.0
-126.0  -27.0   180.0  -81.0
  27.0   36.0   -81.0  180.0]
M_SS = M_MM = [
 40.0   0.0  20.0   0.0
  0.0  40.0   0.0  20.0
 20.0   0.0  40.0   0.0
  0.0  20.0   0.0  40.0]
f_S = [-27.0, -81.0, 81.0, -135.0]
f_M = [ 0.0, 0.0, 0.0, 0.0]
K = [K_SS zeros(4,4); zeros(4,4) K_MM]
M = [M_SS zeros(4,4); zeros(4,4) M_MM]
f = [f_S; f_M]

eliminate_boundary_conditions!(problem, K, M, f)
K_expected = [
  441.0  -81.0  -279.0   81.0
  -81.0  684.0    81.0  -36.0
 -279.0   81.0   333.0  -81.0
   81.0  -36.0   -81.0  252.0]
f_expected = [108.0, -243.0, -54.0, 27.0]

@test isapprox(K[5:8,5:8], K_expected)
@test isapprox(f[5:8], f_expected)
