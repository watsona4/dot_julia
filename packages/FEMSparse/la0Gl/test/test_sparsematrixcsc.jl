using FEMSparse, SparseArrays, Test

K = sparse(Float64[1 0 1 1;
                   0 1 0 1;
                   1 0 1 0;
                   1 1 0 1];)

f = zeros(4)
fill!(K, 0.0)

dofs1 = [1, 3]
dofs2 = [2, 4]
dofs3 = [1, 4]
Ke = ones(2, 2)
fe = ones(2)
assembler = FEMSparse.start_assemble(K, f)
for dofs in (dofs1, dofs2, dofs3)
    FEMSparse.assemble_local!(assembler, dofs, Ke, fe)
end

@test Matrix(K) ≈  [2.0  0.0  1.0  1.0;
                    0.0  1.0  0.0  1.0;
                    1.0  0.0  1.0  0.0;
                    1.0  1.0  0.0  2.0]

@test f == [2.0, 1.0, 1.0, 2.0]
