# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/FEMBeam.jl/blob/master/LICENSE

using FEMBeam
using FEMBase.Test

X = Dict(
    1 => [0.0, 0.0, 0.0],
    2 => [3.0, 0.0, 0.0])
el1 = Element(Seg2, [1, 2])
beams = [el1]
update!(beams, "geometry", X)
update!(beams, "youngs modulus", 210.0e6)
update!(beams, "shear modulus", 84.0e6)
update!(beams, "cross-section area", 20.0e-2)
update!(beams, "torsional moment of inertia y", 10.0e-5)
update!(beams, "torsional moment of inertia z", 20.0e-5)
update!(beams, "polar moment of inertia", 5.0e-5)
update!([el1], "normal", [0.0, 1.0, 0.0])
problem = Problem(Beam, "example 0", 6)
add_elements!(problem, [el1])
time = 0.0
assemble!(problem, time)
K = full(problem.assembly.K)
K_expected = [    1.4e7      0.0       0.0       0.0       0.0      0.0  -1.4e7      0.0       0.0       0.0       0.0      0.0
                  0.0    18666.7       0.0       0.0       0.0  28000.0   0.0    18666.7       0.0       0.0       0.0  28000.0
                  0.0        0.0    9333.33      0.0  -14000.0      0.0   0.0        0.0    9333.33      0.0  -14000.0      0.0
                  0.0        0.0       0.0    1400.0       0.0      0.0   0.0        0.0       0.0   -1400.0       0.0      0.0
                  0.0        0.0  -14000.0       0.0   28000.0      0.0   0.0        0.0  -14000.0       0.0   14000.0      0.0
                  0.0    28000.0       0.0       0.0       0.0  56000.0   0.0    28000.0       0.0       0.0       0.0  28000.0
                 -1.4e7      0.0       0.0       0.0       0.0      0.0   1.4e7      0.0       0.0       0.0       0.0      0.0
                  0.0    18666.7       0.0       0.0       0.0  28000.0   0.0    18666.7       0.0       0.0       0.0  28000.0
                  0.0        0.0    9333.33      0.0  -14000.0      0.0   0.0        0.0    9333.33      0.0  -14000.0      0.0
                  0.0        0.0       0.0   -1400.0       0.0      0.0   0.0        0.0       0.0    1400.0       0.0      0.0
                  0.0        0.0  -14000.0       0.0   14000.0      0.0   0.0        0.0  -14000.0       0.0   28000.0      0.0
                  0.0    28000.0       0.0       0.0       0.0  28000.0   0.0    28000.0       0.0       0.0       0.0  56000.0
]
@test isapprox(K, K_expected)
