

# BlockDiagonalFactors

<p>
  <a href="https://doi.org/<DOI>">
    <img src="https://zenodo.org/badge/DOI/<DOI>.svg" alt="DOI">
  </a>
  <a href="https://github.com/briochemc/BlockDiagonalFactors.jl/blob/master/LICENSE">
    <img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-yellow.svg">
  </a>
</p>
<p>
  <a href="https://briochemc.github.io/BlockDiagonalFactors.jl/stable/">
    <img src=https://img.shields.io/badge/docs-stable-blue.svg>
  </a>
  <a href="https://briochemc.github.io/BlockDiagonalFactors.jl/latest/">
    <img src=https://img.shields.io/badge/docs-dev-blue.svg>
  </a>
  (coming soon!)
</p>
<p>
  <a href="https://travis-ci.com/briochemc/BlockDiagonalFactors.jl">
    <img alt="Build Status" src="https://travis-ci.com/briochemc/BlockDiagonalFactors.jl.svg?branch=master">
  </a>
  <a href='https://coveralls.io/github/briochemc/BlockDiagonalFactors.jl'>
    <img src='https://coveralls.io/repos/github/briochemc/BlockDiagonalFactors.jl/badge.svg' alt='Coverage Status' />
  </a>
</p>
<p>
  <a href="https://ci.appveyor.com/project/briochemc/BlockDiagonalFactors-jl">
    <img alt="Build Status" src="https://ci.appveyor.com/api/projects/status/prm2xfd6q5pba1om?svg=true">
  </a>
  <a href="https://codecov.io/gh/briochemc/BlockDiagonalFactors.jl">
    <img src="https://codecov.io/gh/briochemc/BlockDiagonalFactors.jl/branch/master/graph/badge.svg" />
  </a>
</p>

This package allows you to solve linear systems of the type `M * x = b` where `M` is block diagonal (sparse or not).
It is particularly efficient if some of the blocks of `M` are repeated, because it will only compute the factorizations of these repeated objects once.

### Usage

Consider the block-diagonal matrix
```julia
M = [A ⋅ ⋅ ⋅ ⋅ ⋅ ⋅ ⋅ ⋅
     ⋅ A ⋅ ⋅ ⋅ ⋅ ⋅ ⋅ ⋅
     ⋅ ⋅ B ⋅ ⋅ ⋅ ⋅ ⋅ ⋅
     ⋅ ⋅ ⋅ A ⋅ ⋅ ⋅ ⋅ ⋅
     ⋅ ⋅ ⋅ ⋅ C ⋅ ⋅ ⋅ ⋅
     ⋅ ⋅ ⋅ ⋅ ⋅ A ⋅ ⋅ ⋅
     ⋅ ⋅ ⋅ ⋅ ⋅ ⋅ C ⋅ ⋅
     ⋅ ⋅ ⋅ ⋅ ⋅ ⋅ ⋅ B ⋅
     ⋅ ⋅ ⋅ ⋅ ⋅ ⋅ ⋅ ⋅ A]
```

Instead of creating that big matrix, factorizing it whole, or factorizing each block, you can create a `BlockFactors` or `SparseBlockFactors` object (depending if `A`, `B`, and `C` are sparse) via the following syntax

```julia
# Form an array of the matrices
Ms = [A, B, C]

# and an array of "repetition" indices
indices = [1, 1, 2, 1, 3, 1, 3, 2, 1]

# to create the Block Diagonal Factors (BDF) object
BDF = factorize(Ms, indices)
```

This way `A`, `B`, and `C` are factorized only once.
Then, you can solve for linear system `M * x = b` 
- via backslash (same as `M \ b`)

    ```julia
    x = BDF \ b
    ```

- via the inplace (same as `ldiv!(M, b)`)
    ```julia
    ldiv!(BDF, b)
    ```

- or via the inplace (same as `ldiv!(x, M, b)`)
    ```julia
    ldiv!(x, BDF, b)
    ```

### How it works

The package simply creates two new types, `BlockFactors` or `SparseBlockFactors`, which look like
```julia
struct (Sparse)BlockFactors{Tv}
    factors::Vector
    indices::Vector{<:Int}
    m::Int
    n::Int
end
```
and overloads `factorize`, `lu`, and other factorization functions to create those objects from an array of matrices and the repeating indices.
In order to solve linear systems it also overloads `\` and `ldiv!`.
That's it!

### Cite it!

If you use this package directly, please cite it!
Use the [CITATION.bib](./CITATION.bib), which contains a bibtex entry for the software (coming soon).
