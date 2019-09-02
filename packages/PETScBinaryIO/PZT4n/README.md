# PETScBinaryIO.jl

A Julia package for reading and writing sparse matrices in a format PETSc understands.

## Exported Functions

```julia
writepetsc(filename, objs :: Vector{Union{SparseMatrixCSC, Vector}})
writepetsc(filename, mat :: SparseMatrixCSC)
writepetsc(filename, vec :: Vector)
```

Write a sparse matrix to `filename` in a format PETSc can understand.

```julia
readpetsc(filename) :: Vector{Union{SparseMatrixCSC, Vector}}
```

Read a sparse matrix in PETSc's binary format from `filename`.
