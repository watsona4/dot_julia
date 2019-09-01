# FEMSparse.jl

[![][travis-img]][travis-url]
[![][pkg-0.7-img]][pkg-0.7-url]
[![][pkg-1.0-img]][pkg-1.0-url]
[![][coveralls-img]][coveralls-url]
[![][issues-img]][issues-url]

FEMSparse package contains sparse matrix operations spesifically designed for
finite element simulations. In particular, we aim to provide support for
sparse matrices which are fast to fill with dense local element matrices.
In literature, this is called to *finite element assembly procedure*, where
element local degrees of freedom are connected to the global degrees of freedom
of model. Typically this procedure looks something similar to below:

```julia
K = zeros(N, N)
Ke = [1.0 -1.0; -1.0 1.0]
dofs1 = [4, 5]
dofs2 = [4, 5]
K[dofs1, dofs2] += Ke
```

## Performance test

To demonstrate the performance of the package, Poisson problem in 1 dimension
is assembled (see `examples/poisson1d.jl`) using three different strategies:
1) assemble to dense matrix, like shown above
2) assemble to sparse matrix of CSC format
3) assemble to sparse matrix of COO format

### Assembling to dense matrix

```bash
[ Info: Dense matrix:
 2.298 s (30004 allocations: 6.71 GiB)
```

Dense matrix is not suitable for global (sparse) assembly due to it's massive
requirement of available memory.

### Assembling to the sparse matrix format CSC

#### Naive attempt

```bash
[ Info: Sparse matrix (CSC format):
 15.536 s (568673 allocations: 26.97 GiB)
```

`SparseMatrixCSC` is not suitable for (naive) assembly because the change of
sparsity pattern is very expensive.

#### Use of existing sparsity pattern

However, if an existing "sparsity pattern" exist (a sparse matrix where the locations of all non zeros
have already been allocated) it is possible to efficiently assemble directly into it.

For example,

```julia
julia> K = sparse(Float64[1 0 1 1;
                          0 1 0 1;
                          1 0 1 0;
                          1 1 0 1];)

julia> fill!(K, 0.0)

julia> K.colptr'
1×5 LinearAlgebra.Adjoint{Int64,Array{Int64,1}}:
 1  3  5  7  9

julia> K.rowval'
1×8 LinearAlgebra.Adjoint{Int64,Array{Int64,1}}:
 1  3  2  4  1  3  2  4
```

Assembling into this sparsity pattern is now done by

```julia
dofs1 = [1, 3]
dofs2 = [2, 4]
dofs3 = [1, 4]
Ke1 = ones(2, 2)
Ke2 = ones(2, 2)
Ke3 = ones(2, 2)
assembler = FEMSparse.start_assemble(K)
for (dofs, Ke) in zip([dofs1, dofs2, dofs3], [Ke1, Ke2, Ke3])
    FEMSparse.assemble_local_matrix!(assembler, dofs, Ke)
end
```

resulting in that the content of `K` (here shown as a dense matrix for clarity) contains:

```
4×4 Array{Float64,2}:
 2.0  0.0  1.0  1.0
 0.0  1.0  0.0  1.0
 1.0  0.0  1.0  0.0
 1.0  1.0  0.0  2.0
```

### Assembling to the sparse matrix format COO

```bash
[ Info: Sparse matrix (COO format):
 5.854 ms (73 allocations: 9.89 MiB)
```

`SparseMatrixCOO` is suitable sparse format for assembling global matrices, yet
it still have some shortcomings. In practice for solving linear system, COO format
needs to be converted to CSC format and it costs. Thus it would be benefical to do
first-time assembly in COO format, and after that store the sparsity pattern and
move to use direct assembly to CSC format.


[gitter-url]: https://gitter.im/JuliaFEM/JuliaFEM.jl

[docs-latest-img]: https://img.shields.io/badge/docs-latest-blue.svg
[docs-latest-url]: https://juliafem.github.io/FEMSparse.jl/latest

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://juliafem.github.io/FEMSparse.jl/stable

[travis-img]: https://travis-ci.org/JuliaFEM/FEMSparse.jl.svg?branch=master
[travis-url]: https://travis-ci.org/JuliaFEM/FEMSparse.jl

[coveralls-img]: https://coveralls.io/repos/github/JuliaFEM/FEMSparse.jl/badge.svg?branch=master
[coveralls-url]: https://coveralls.io/github/JuliaFEM/FEMSparse.jl?branch=master

[issues-img]: https://img.shields.io/github/issues/JuliaFEM/FEMSparse.jl.svg
[issues-url]: https://github.com/JuliaFEM/FEMSparse.jl/issues

[pkg-0.7-img]: http://pkg.julialang.org/badges/FEMSparse_0.7.svg
[pkg-0.7-url]: http://pkg.julialang.org/?pkg=FEMSparse&ver=0.7
[pkg-1.0-img]: http://pkg.julialang.org/badges/FEMSparse_1.0.svg
[pkg-1.0-url]: http://pkg.julialang.org/?pkg=FEMSparse&ver=1.0
