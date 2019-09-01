# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/FEMBeam.jl/blob/master/LICENSE

## Rotation matrix test

using FEMBeam
using FEMBeam: get_rotation_matrix
using FEMBase.Test

# If tangent vector ``t`` is parallel to the first beam section axis ``n_1``,
# local basis is not uniquely defined and error is thrown.

X1 = [0.0, 0.0, 0.0]
X2 = [1.0, 0.0, 0.0]
n1 = [1.0, 0.0, 0.0]
@test_throws Exception get_rotation_matrix(X1, X2, n1)
