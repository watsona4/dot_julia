# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/FEMSparse.jl/blob/master/LICENSE

using FEMSparse, SparseArrays, Test

# SparseMatrixCOO initialization:

K = SparseMatrixCOO()
@test SparseMatrixCOO(zeros(5,5)) == SparseMatrixCOO(spzeros(5,5))

# Converting to Matrix

Ke = [1.0 2.0; 3.0 4.0]
@test Matrix(SparseMatrixCOO(Ke)) == Ke

# Assemble data to SparseMatrixCOO

dofs1 = [2, 3]
dofs2 = [1, 2]
add!(K, dofs1, dofs2, Ke)
K_expected = zeros(3,2)
K_expected[dofs1, dofs2] = Ke
@test isapprox(K, K_expected)
