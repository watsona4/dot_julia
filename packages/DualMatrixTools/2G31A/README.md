# DualMatrixTools.jl

<p>
  <a href="https://doi.org/10.5281/zenodo.1493571">
    <img src="https://zenodo.org/badge/DOI/10.5281/zenodo.1493571.svg" alt="DOI">
  </a>
  <a href="https://briochemc.github.io/DualMatrixTools.jl/stable">
    <img src=https://img.shields.io/badge/docs-stable-blue.svg>
  </a>
  <a href="https://travis-ci.com/briochemc/DualMatrixTools.jl">
    <img alt="Build Status" src="https://travis-ci.com/briochemc/DualMatrixTools.jl.svg?branch=master">
  </a>
  <a href="https://travis-ci.org/briochemc/DualMatrixTools.jl">
    <img alt="Build Status" src="https://travis-ci.org/briochemc/DualMatrixTools.jl.svg?branch=master">
  </a>
  <a href='https://coveralls.io/github/briochemc/DualMatrixTools.jl'>
    <img src='https://coveralls.io/repos/github/briochemc/DualMatrixTools.jl/badge.svg' alt='Coverage Status' />
  </a>
  <a href="https://codecov.io/gh/briochemc/DualMatrixTools.jl">
    <img src="https://codecov.io/gh/briochemc/DualMatrixTools.jl/branch/master/graph/badge.svg" />
  </a>
  <a href="https://github.com/briochemc/DualMatrixTools.jl/blob/master/LICENSE">
    <img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-yellow.svg">
  </a>
</p>

This package provides an overloaded `factorize` and `\` that work with dual-valued arrays.

It uses the dual type defined by the [DualNumbers.jl](https://github.com/JuliaDiff/DualNumbers.jl) package.
The idea is that for a dual-valued matrix

<a href="https://www.codecogs.com/eqnedit.php?latex=\fn_phv&space;M&space;=&space;A&space;&plus;&space;\varepsilon&space;B" target="_blank"><img src="https://latex.codecogs.com/gif.latex?\fn_phv&space;M&space;=&space;A&space;&plus;&space;\varepsilon&space;B" title="M = A + \varepsilon B" /></a>,

its inverse is given by

<a href="https://www.codecogs.com/eqnedit.php?latex=\fn_phv&space;M^{-1}&space;=&space;(I&space;-&space;\varepsilon&space;A^{-1}&space;B)&space;A^{-1}" target="_blank"><img src="https://latex.codecogs.com/gif.latex?\fn_phv&space;M^{-1}&space;=&space;(I&space;-&space;\varepsilon&space;A^{-1}&space;B)&space;A^{-1}" title="M^{-1} = (I - \varepsilon A^{-1} B) A^{-1}" /></a>.

Therefore, only the inverse of <a href="https://www.codecogs.com/eqnedit.php?latex=\fn_phv&space;A" target="_blank"><img src="https://latex.codecogs.com/gif.latex?\fn_phv&space;A" title="A" /></a> is required to evaluate the inverse of <a href="https://www.codecogs.com/eqnedit.php?latex=\fn_phv&space;M" target="_blank"><img src="https://latex.codecogs.com/gif.latex?\fn_phv&space;M" title="M" /></a>.
This package makes available a `DualFactors` type which containts (i) the factors of <a href="https://www.codecogs.com/eqnedit.php?latex=\fn_phv&space;A" target="_blank"><img src="https://latex.codecogs.com/gif.latex?\fn_phv&space;A" title="A" /></a> and (ii) the non-real part, <a href="https://www.codecogs.com/eqnedit.php?latex=\fn_phv&space;B" target="_blank"><img src="https://latex.codecogs.com/gif.latex?\fn_phv&space;B" title="B" /></a>.
It also overloads `factorize` to create an instance of `DualFactors` (when invoked with a dual-valued matrix), which can then be called with `\` to efficiently solve dual-valued linear systems of the type <a href="https://www.codecogs.com/eqnedit.php?latex=\fn_phv&space;M&space;x&space;=&space;b" target="_blank"><img src="https://latex.codecogs.com/gif.latex?\fn_phv&space;M&space;x&space;=&space;b" title="M x = b" /></a>.

This package should be useful for autodifferentiation of functions that use `\`.
Note the same idea extends to hyper dual numbers (see the [HyperDualMatrixTools.jl](https://github.com/briochemc/HyperDualMatrixTools.jl) package).

## Usage

1. Create your dual-valued matrix `M`:
    ```julia
    julia> M = A + ε * B
    ```

2. Apply `\` to solve systems of the type `M * x = b`
    - without factorization:
        ```julia
        julia> x = M \ b
        ```

    - or better, with prior factorization:
        ```julia
        julia> Mf = factorize(M)

        julia> x = Mf \ b
        ```
        (This is better in case you want to solve for another `b`!)

## Advanced usage

In the context of iterative processes with multiple factorizations and forward and back substitutions, you may want to propagate dual-valued numbers while leveraging (potentially) the fact the real part of the matrices to be factorized remains the same throughout.
This package provides an in-place `factorize`, with a flag to update (or not) the factors.
Usage is straightforward.
By default, `factorize` does *not* update the factors
```julia
julia> factorize(Mf, M) # only Mf.B is updated
```
If you want to update the real-valued factors too, use
```julia
julia> factorize(Mf, M, update_factors=true) # Mf.B and Mf.Af are updated
```

## Citation

If you use this package, please cite it!
You can export the citation by first clicking on the DOI badge at the top, which links to the Zenodo record of the package, and then clicking on the citation format you want in the "Export" box at the bottom of the page.

