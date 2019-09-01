# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/FEMSparse.jl/blob/master/LICENSE

# Sparse assembly test, 1d poisson equation:
# $$u'' = 0$$,
# $$u(0) = 0$$,
# $$u(1) = 1$$,
# discretized to $$N$$ elements.

using Test, BenchmarkTools, LinearAlgebra, SparseArrays
using Revise
using FEMSparse

function fill_dense(N)
    h = 1.0/N
    Ke = h*[1.0 -1.0; -1.0 1.0]
    K = zeros(N+1, N+1)
    for i in 1:N
        K[i:i+1,i:i+1] .+= Ke
    end
    return K
end

function fill_sparse_csc(N)
    h = 1.0/N
    Ke = h*[1.0 -1.0; -1.0 1.0]
    K = spzeros(N+1, N+1)
    for i in 1:N
        K[i:i+1,i:i+1] += Ke
    end
    return K
end

function fill_sparse_coo(N)
    h = 1.0/N
    Ke = h*[1.0 -1.0; -1.0 1.0]
    K = SparseMatrixCOO()
    for i in 1:N
        add!(K, i:i+1, i:i+1, Ke)
    end
    return SparseMatrixCSC(K)
end

function test_assembly(K)
    N = size(K,1)-1
    # set boundary conditions: u(0) = 0, u(1) = 1
    u = zeros(N+1)
    u[end] = 1.0
    f = -K*u
    K[1,:] .= 0.0
    K[:,1] .= 0.0
    K[1,1] = 1.0
    f[end] = 0.0
    K[end,:] .= 0.0
    K[:,end] .= 0.0
    K[end,end] = 1.0
    f[end] = 1.0
    u = K\f
    u_acc = collect(range(0.0, stop=1.0, length=N+1))
    return isapprox(u, u_acc; atol=1.0e-12)
end

@info("Warm-up")

@test test_assembly(fill_dense(10))
@test test_assembly(fill_sparse_csc(10))
@test test_assembly(fill_sparse_coo(10))

@info("Test")

@info("Dense matrix:")
@btime fill_dense(30_000)

@info("Sparse matrix (CSC format):")
@btime fill_sparse_csc(30_000)

@info("Sparse matrix (COO format):")
@btime fill_sparse_coo(30_000)
