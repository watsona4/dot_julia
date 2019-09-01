# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/FEMBeam.jl/blob/master/LICENSE

using FEMBeam, Test
using FEMBeam: get_beam_stiffness_matrix_2d, get_beam_forces_vector_2d,
               get_beam_mass_matrix_2d

beam_element = Element(Seg2, [1, 2])
problem = Problem(Beam2D, "test problem", 3)
add_elements!(problem, [beam_element])

@test get_unknown_field_name(problem) == "displacement"
@test assemble!(problem, 0.0) == nothing

## Beam 1

X1 = [0.0, 0.0]
X2 = [0.0, 6.5]
E = 210.0e9
I1 = 50.8e-3*101.6e-3^3/12
A = 50.8e-3*101.6e-3
rho = 7800.0
qt = -500.0
qn = 0.0
fp = zeros(6)

k = get_beam_stiffness_matrix_2d(X1, X2, E, I1, A)
f = get_beam_forces_vector_2d(X1, X2, qt, qn, fp)
m = get_beam_mass_matrix_2d(X1, X2, A, rho)

m_expected = [
  97.1943   0.0     -89.0948   33.6442   0.0      52.6469
   0.0     87.2256    0.0       0.0     43.6128    0.0
 -89.0948   0.0     105.294   -52.6469   0.0     -78.9703
  33.6442   0.0     -52.6469   97.1943   0.0      89.0948
   0.0     43.6128    0.0       0.0     87.2256    0.0
  52.6469   0.0     -78.9703   89.0948   0.0     105.294]

k_expected = [
40740.3         0.0            -1.32406e5  -40740.3         0.0            -1.32406e5
    0.0         1.66749e8       0.0             0.0        -1.66749e8       0.0
   -1.32406e5   0.0        573759.0             1.32406e5   0.0             2.8688e5
-40740.3         0.0             1.32406e5   40740.3         0.0             1.32406e5
    0.0        -1.66749e8       0.0             0.0         1.66749e8       0.0
   -1.32406e5   0.0             2.8688e5        1.32406e5   0.0        573759.0]

f_expected = [1625.0, 0.0, -1760.42, 1625.0, 0.0, 1760.42]

@test isapprox(m, m_expected; rtol=1.0e-5)
@test isapprox(k, k_expected; rtol=1.0e-5)
@test isapprox(f, f_expected; rtol=1.0e-5)

## Beam 2

X1 = [0.0, 6.5]
X2 = [8.0, 6.5]
E = 250.0e9
I1 = 75.0e-3*100.0e-3^3/12
A = 75.0e-3*100.0e-3
rho = 10000.0
qt = -750.0
qn = 0.0
fp = zeros(6)

m = get_beam_mass_matrix_2d(X1, X2, A, rho)
k = get_beam_stiffness_matrix_2d(X1, X2, E, I1, A)
f = get_beam_forces_vector_2d(X1, X2, qt, qn, fp)

m_expected = [
200.0     0.0        0.0    100.0     0.0        0.0
  0.0   222.857    251.429    0.0    77.1429  -148.571
  0.0   251.429    365.714    0.0   148.571   -274.286
100.0     0.0        0.0    200.0     0.0        0.0
  0.0    77.1429   148.571    0.0   222.857   -251.429
  0.0  -148.571   -274.286    0.0  -251.429    365.714]

k_expected = [
  2.34375e8       0.0        0.0  -2.34375e8        0.0        0.0
  0.0         36621.1   146484.0   0.0         -36621.1   146484.0
  0.0        146484.0   781250.0   0.0        -146484.0   390625.0
 -2.34375e8       0.0        0.0   2.34375e8        0.0        0.0
  0.0        -36621.1  -146484.0   0.0          36621.1  -146484.0
  0.0        146484.0   390625.0   0.0        -146484.0   781250.0]

f_expected = [0.0, -3000.0, -4000.0, 0.0, -3000.0, 4000.0]

@test isapprox(m, m_expected; rtol=1.0e-5)
@test isapprox(k, k_expected; rtol=1.0e-5)
@test isapprox(f, f_expected; rtol=1.0e-5)

## Beam 3

X1 = [8.0, 6.5]
X2 = [8.0, 0.0]
E = 160.0e9
I1 = 50.0e-3*50.0e-3^3/12
A = 50.0e-3*50.0e-3
rho = 6000.0
qt = 0.0
qn = 0.0
fp = zeros(6)

m = get_beam_mass_matrix_2d(X1, X2, A, rho)
k = get_beam_stiffness_matrix_2d(X1, X2, E, I1, A)
f = get_beam_forces_vector_2d(X1, X2, qt, qn, fp)

m_expected = [
36.2143   0.0    33.1964   12.5357   0.0   -19.6161
 0.0     32.5     0.0       0.0     16.25    0.0
33.1964   0.0    39.2321   19.6161   0.0   -29.4241
12.5357   0.0    19.6161   36.2143   0.0   -33.1964
 0.0     16.25    0.0       0.0     32.5     0.0
-19.6161   0.0   -29.4241  -33.1964   0.0    39.2321]

k_expected = [
  3641.33   0.0         11834.3   -3641.33   0.0         11834.3
     0.0    6.15385e7       0.0       0.0   -6.15385e7       0.0
 11834.3    0.0         51282.1  -11834.3    0.0         25641.0
 -3641.33   0.0        -11834.3    3641.33   0.0        -11834.3
     0.0   -6.15385e7       0.0       0.0    6.15385e7       0.0
 11834.3    0.0         25641.0  -11834.3    0.0         51282.1]

f_expected = zeros(6)

@test isapprox(m, m_expected; rtol=1.0e-5)
@test isapprox(k, k_expected; rtol=1.0e-5)
@test isapprox(f, f_expected; rtol=1.0e-5)
