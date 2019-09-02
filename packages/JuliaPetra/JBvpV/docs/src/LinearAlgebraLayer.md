# Linear Algebra Layer

```@meta
CurrentModule = JuliaPetra
```

The Linear Algebra layer provides the main abstractions for linear algebra codes.
The two top level interfaces are [`MultiVector`](@ref), for groups of vectors, and [`Operator`](@ref), for operations on `MultiVector`s.

## MultiVectors

MutliVectors support many basic array functions, including broadcasting.
Additionally, [`dot`] and [`norm`] are supported, however they return arrays since [`MultiVector`]s may have multiple dot products and norms.

```@docs
MultiVector
DenseMultiVector
localLength
globalLength
numVectors
getVectorView
getVectorCopy
getLocalArray
commReduce
```

## Operators

`Operator`s represent an operation on a [`MultiVector`](@ref), such as a matrix which applies a matrix-vector product.

```@docs
Operator
getRangeMap
getDomainMap
apply!
apply
TransposeMode
isTransposed
applyConjugation
```

### Matrices

Sparse matrices are the primary [`Operator`](@ref) in JuliaPetra.

```@docs
RowMatrix
CSRMatrix
```
