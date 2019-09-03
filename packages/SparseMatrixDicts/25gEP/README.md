# SparseMatrixDicts

[![Build Status](https://travis-ci.org/masuday/SparseMatrixDicts.jl.svg?branch=master)](https://travis-ci.org/masuday/SparseMatrixDicts.jl)

## Quick start

This package creates a sparse matrix as Dictionary.
You can convert the dictionary to a SparseCSC matrix or a dense matrix.
It is useful when the nonzero elements randomly occur and you can not prepare the sparse storage before you see the actual elements.

The constructor of the matrix is `SparseMatrixDict{Tv,Ti}(m,n)` where `Tv` is the type of element (default:`Float64`), `Ti` is the type of index (default:`Int`), `m` is the number of rows, and `n` is the number of columns.
A pair of indices (row *i* and column *j*) will be treated as a tuple `(i,j)` and it is the key of dictionary; `Dict{Tuple{Ti,Ti},Tv}`.

## Examples

```
using SparseMatrixDicts
n = 5
A = SparseMatrixDict(n,n)  # default={Float64,Int}

# assignment; similar to regular matrices
A[1,1] = 2.0
A[2,5] = 1.0

# convert to dense matrix
dA = Matrix(A)

# convert to sparse matrix CSC
sA = SparseMatrixCSC(A)

# make a symmetric sparse matrix
symA = Symmetric(SparseMatrixCSC(A),:U)  # :U for upper
```
